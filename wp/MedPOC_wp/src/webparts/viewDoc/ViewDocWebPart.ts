import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import {
  BaseClientSideWebPart,
  IPropertyPaneConfiguration,
  PropertyPaneTextField,
  PropertyPaneDropdown
} from '@microsoft/sp-webpart-base';
import * as strings from 'ViewDocWebPartStrings';
import ListItems from './components/ListItems';
import { IListItemsProps  } from './components/IListItemsProps ';
import { IViewDocWebPartProps } from './IViewDocWebPartProps';
import { PropertyPaneAsyncDropdown } from './PropertyPaneAsyncDropdown';
import { IDropdownOption } from 'office-ui-fabric-react/lib/components/Dropdown';
import { update, get } from '@microsoft/sp-lodash-subset';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';

export default class ViewDocWebPart extends BaseClientSideWebPart<IViewDocWebPartProps> {

  public render(): void {
    const element: React.ReactElement<IListItemsProps> = React.createElement(ListItems, {
       // spHttpClient: this.context.spHttpClient,
       // siteUrl: this.context.pageContext.web.absoluteUrl,
        listName: this.properties.listName,
        item: this.properties.item
      }
    );

    ReactDom.render(element, this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }
  
  //Replace this one with REST for actual list
  private loadLists(): Promise<IDropdownOption[]> {
    return new Promise<IDropdownOption[]>((resolve: (options: IDropdownOption[]) => void, reject: (error: any) => void) => {
      setTimeout(() => {
        resolve([{
          key: 'sharedDocuments',
          text: 'Shared Documents'
        },
          {
            key: 'myDocuments',
            text: 'My Documents'
          }]);
      }, 2000);
    });
  }
  
  private onListChange(propertyPath: string, newValue: any): void {
    const oldValue: any = get(this.properties, propertyPath);
    // store new value in web part properties
    update(this.properties, propertyPath, (): any => { return newValue; });
    // refresh web part
    this.render();
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: {
            description: strings.PropertyPaneDescription
          },
          groups: [
            {
              groupName: strings.DataGroupName,
              groupFields: [
                new PropertyPaneAsyncDropdown('listName', {
                  label: strings.ListFieldLabel,
                  loadOptions: this.loadLists.bind(this),
                  onPropertyChange: this.onListChange.bind(this),
                  selectedKey: this.properties.listName
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
