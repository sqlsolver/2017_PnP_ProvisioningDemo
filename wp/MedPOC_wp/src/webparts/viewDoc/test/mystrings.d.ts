declare interface IListItemsWebPartStrings {
  PropertyPaneDescription: string;
  DataGroupName: string;
  ListFieldLabel: string;
  ItemFieldLabel: string;
}

declare module 'ViewDocWebPartStrings' {
  const strings: IListItemsWebPartStrings;
  export = strings;
}
