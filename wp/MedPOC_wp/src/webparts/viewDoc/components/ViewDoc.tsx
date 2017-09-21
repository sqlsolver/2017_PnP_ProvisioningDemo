import * as React from 'react';
import styles from './ViewDoc.module.scss';
import { IViewDocProps } from './IViewDocProps';
import { escape } from '@microsoft/sp-lodash-subset';
import {  
  DocumentCard,
  DocumentCardPreview,
  DocumentCardTitle,
  DocumentCardActivity,
  Spinner
} from 'office-ui-fabric-react';

export default class ViewDoc extends React.Component<IViewDocProps, {}> {
  public render(): React.ReactElement<IViewDocProps> {
    return (
      <div className={styles.viewDoc}>
        <div className={styles.container}>
          <div className={`ms-Grid-row ms-bgColor-themeDark ms-fontColor-white ${styles.row}`}>
            <div className="ms-Grid-col ms-lg10 ms-xl8 ms-xlPush2 ms-lgPush1">
              <span className="ms-font-xl ms-fontColor-white">Welcome to Physician Preview!</span>
              <p className="ms-font-l ms-fontColor-white">Select the provider best suited to your conditon.</p>
              <p className="ms-font-l ms-fontColor-white">{escape(this.props.description)}</p>
              <a href="https://aka.ms/spfx" className={styles.button}>
                <span className={styles.label}>Learn more</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    );
  }
}