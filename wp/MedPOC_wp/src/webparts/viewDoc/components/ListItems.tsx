import * as React from 'react';
import styles from '../components/ViewDoc.module.scss';
import { IListItemsProps } from '../components/IListItemsProps ';
// import { IItemState} from '../components/IItemState';
import { escape } from '@microsoft/sp-lodash-subset';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';

export default class ListItems extends React.Component<IListItemsProps, {}> {
  public render(): React.ReactElement<IListItemsProps> {
    return (
      <div className={styles.viewDoc}>
        <div className={styles.container}>
          <div className={`ms-Grid-row ms-bgColor-greenLight ms-fontColor-white ${styles.row}`}>
            <div className="ms-Grid-col ms-lg10 ms-xl8 ms-xlPush2 ms-lgPush1">
              <span className="ms-font-xl ms-fontColor-purple">Welcome to Physician Preview!</span>
              <p className="ms-font-l ms-fontColor-white">Selection:</p>
              <p className="ms-font-l ms-fontColor-white">{escape(this.props.listName)}</p>
              <p className="ms-font-l ms-fontColor-white">{escape(this.props.item)}</p>
              <a href="https://github.com/sqlsolver/2017_PnP_ProvisioningDemo/wiki" className={styles.button}>
                <span className={styles.label}>PnP Demo</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    );
  }


  public componentWillReceiveProps(nextProps: IListItemsProps ): void {
    this.listNotConfigured != null;
    this.setState({
      status: this.listNotConfigured(nextProps) ? 'Please configure list in Web Part properties' : 'Ready',
      items: []
    });
  }

  private listNotConfigured(props: IListItemsProps ): boolean {
    return props.listName === undefined ||
      props.listName === null ||
      props.listName.length === 0;
  }
}

const disabled: string = this.listNotConfigured(this.props) ? styles.disabled : ''; 