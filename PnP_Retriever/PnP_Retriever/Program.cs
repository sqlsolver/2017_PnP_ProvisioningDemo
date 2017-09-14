using System;
using System.Net;
using System.Security;
using System.Threading;
using Microsoft.SharePoint.Client;
using OfficeDevPnP.Core.Framework.Provisioning.Connectors;
using OfficeDevPnP.Core.Framework.Provisioning.Model;
using OfficeDevPnP.Core.Framework.Provisioning.ObjectHandlers;
using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;


namespace PnP_Retriever
{
    class Program
    {
        private static void DisplayMenu()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("PnP Provisioning - Retrieve and Apply Site Templates");
            Console.WriteLine("_____________________________________________________");
            Console.WriteLine("1. Retrieve a template from an existing site");
            Console.WriteLine("2. Apply the template to a new site");
            Console.WriteLine("3. Exit the program.");
            Console.ReadLine();
        }

        static void Main(string[] args)
        {
        
        ConsoleColor defaultForeground = Console.ForegroundColor;

            // Collect information 
            string templateWebUrl = GetInput("Enter the URL of the template site: ", false, defaultForeground);
            string targetWebUrl = GetInput("Enter the URL of the target site: ", false, defaultForeground);
            string userName = GetInput("Enter your user name:", false, defaultForeground);
            string pwdS = GetInput("Enter your password:", true, defaultForeground);
            string userChoice = GetInput("Please enter your choice from the menu options:", true, defaultForeground);
            SecureString pwd = new SecureString();
            foreach (char c in pwdS.ToCharArray()) pwd.AppendChar(c);
            //ConsoleKeyInfo cki;
            ProvisioningTemplate template = null;
            DisplayMenu();

            do
            {
                DisplayMenu();
                //cki = Console.ReadKey(false); // show the key as you read it
                Console.ReadKey();
                switch (Convert.ToInt32(userChoice)) //(cki.KeyChar.ToString())
                {
                    case 1:
                        template = GetProvisioningTemplate(defaultForeground, templateWebUrl, userName, pwd);
                        break;
                    case 2:
                        if (template != null)
                        {
                            ApplyProvisioningTemplate(defaultForeground, targetWebUrl, userName, pwd, template);
                        }
                        break;
                    case 3:
                        {
                            Console.WriteLine();
                            Console.Write("Do you want to exit the provisioning program? (y, n): ");
                            char YN = Console.ReadLine()[0];
                            if (YN == 'y' || YN == 'Y')
                                {
                                    Environment.Exit(0);
                                }
                            else if (YN == 'n' || YN == 'N')
                                {
                                    Console.WriteLine("Okay, returning to menu...");
                                    DisplayMenu();
                                }
                        }
                        break;
                }
            } while (template != null);
        }

        private static string GetInput(string label, bool isPassword, ConsoleColor defaultForeground)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("{0} : ", label);
            Console.ForegroundColor = defaultForeground;

            string value = "";

            for (ConsoleKeyInfo keyInfo = Console.ReadKey(true); keyInfo.Key != ConsoleKey.Enter; keyInfo = Console.ReadKey(true))
            {
                if (keyInfo.Key == ConsoleKey.Backspace)
                {
                    if (value.Length > 0)
                    {
                        value = value.Remove(value.Length - 1);
                        Console.SetCursorPosition(Console.CursorLeft - 1, Console.CursorTop);
                        Console.Write(" ");
                        Console.SetCursorPosition(Console.CursorLeft - 1, Console.CursorTop);
                    }
                }
                else if (keyInfo.Key != ConsoleKey.Enter)
                {
                    if (isPassword)
                    {
                        Console.Write("*");
                    }
                    else
                    {
                        Console.Write(keyInfo.KeyChar);
                    }
                    value += keyInfo.KeyChar;

                }

            }
            Console.WriteLine("");

            return value;
        }

        private static ProvisioningTemplate GetProvisioningTemplate(ConsoleColor defaultForeground, string webUrl, string userName, SecureString pwd)
        {
            using (var ctx = new ClientContext(webUrl))
            {
                ctx.Credentials = new NetworkCredential(userName, pwd);
                //ctx.Credentials = new SharePointOnlineCredentials(userName, pwd);
                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("Your site title is:" + ctx.Web.Title);
                Console.ForegroundColor = defaultForeground;

                ProvisioningTemplateCreationInformation ptci
                        = new ProvisioningTemplateCreationInformation(ctx.Web);

                // Create FileSystemConnector to store a temporary copy of the template 
                ptci.FileConnector = new FileSystemConnector(@"c:\temp\pnpprovisioning", "");
                ptci.PersistBrandingFiles = true;
                ptci.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    // Only to output progress for console UI
                    Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Execute actual extraction of the template
                ProvisioningTemplate template = ctx.Web.GetProvisioningTemplate(ptci);

                // We can serialize this template to save and reuse it
                // Optional step 
                XMLTemplateProvider provider =
                        new XMLFileSystemTemplateProvider(@"c:\temp\pnpProvisioning", "");
                provider.SaveAs(template, "PnPProvisioning.xml");

                return template;
            }
        }
        private static void ApplyProvisioningTemplate(ConsoleColor defaultForeground, string webUrl, string userName, SecureString pwd, ProvisioningTemplate template)
        {
            using (var ctx = new ClientContext(webUrl))
            {
                ctx.Credentials = new NetworkCredential(userName, pwd);
                //ctx.Credentials = new SharePointOnlineCredentials(userName, pwd);
                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("Your site title is:" + ctx.Web.Title);
                Console.ForegroundColor = defaultForeground;

                // We could potentially also upload the template from file system, but we at least need this for branding file
                XMLTemplateProvider provider = new XMLFileSystemTemplateProvider(@"c:\temp\pnpprovisioning", "");
                template = provider.GetTemplate("PnPProvisioning.xml");

                ProvisioningTemplateApplyingInformation ptai = new ProvisioningTemplateApplyingInformation();
                ptai.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Associate file connector for assets
                FileSystemConnector connector = new FileSystemConnector(@"c:\temp\pnpprovisioning", "");
                template.Connector = connector;

                // Since template is actual object, we can modify this using code as needed
                template.Lists.Add(new ListInstance()
                {
                    Title = "PnP Sample Contacts",
                    Url = "lists/PnPContacts",
                    TemplateType = (Int32)ListTemplateType.Contacts,
                    EnableAttachments = true
                });

                web.ApplyProvisioningTemplate(template, ptai);
            }
        }
    }
}
