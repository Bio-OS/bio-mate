import { BaseWidgetView } from '../basewidget';

export type CommResponseInner =
  | {
      status: 'ok';
      result: any;
    }
  | {
      status: 'failed';
      msg: string;
    };

export interface CommResponse {
  reqId: string;
  method: string;
  params: any;

  response: CommResponseInner;
}

export default class CommRequest {
  widgetView: BaseWidgetView;
  promMap: {
    [key: string]: {
      resolve(val: CommResponse): void;
      reject(): void;
      prom: Promise<CommResponse>;
    };
  };

  constructor({ widgetView }: { widgetView: BaseWidgetView }) {
    this.widgetView = widgetView;
    this.promMap = {};

    widgetView.model.comm?.on_msg((msg: any) => {
      if (msg.content.data.method !== 'custom') return;

      const content = msg.content.data.content;
      if (!content.reqId) {
        console.warn('CommRequest: custom_msg without a reqId', msg);
        return;
      }

      const prom = this.promMap[content.reqId];
      if (!prom) {
        console.warn('CommRequest: custom_msg with a reqId not found', msg);
        return;
      }

      console.log('CommRequest: response', msg.content.data.content);
      prom.resolve(content);
    });
  }

  send({ method, params = {} }: { method: string; params?: object }) {
    const reqId = new Date().toISOString();
    const msg = { reqId, method, params };

    console.log('CommRequest: request', msg);
    this.widgetView.send(msg);

    let tmp: {
      resolve: (value: any) => void;
      reject: (reason?: any) => void;
    };
    const prom = new Promise<CommResponse>((resolve, reject) => {
      tmp = { resolve, reject };
    });

    // @ts-ignore
    this.promMap[reqId] = { ...tmp, prom };

    return prom;
  }

  listFiles(path: string) {
    return this.send({
      method: 'listFiles',
      params: {
        path
      }
    });
  }

  getSampleImage() {
    return this.send({
      method: 'getSampleImage'
    });
  }

  genPlot(params: object) {
    return this.send({
      method: 'genPlot',
      params
    });
  }
}
