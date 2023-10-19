import {
  DOMWidgetModel,
  DOMWidgetView,
  ISerializers
} from '@jupyter-widgets/base';
import { MODULE_NAME, MODULE_VERSION } from './util/consts';
import Backbone from 'backbone';

import ReactDOM from 'react-dom';
import React from 'react';
import Plot from './Plot';

// noinspection JSAnnotator
export class BaseWidgetModel extends DOMWidgetModel {
  static model_name = 'BaseWidgetModel';
  static model_module = MODULE_NAME;
  static model_module_version = MODULE_VERSION;
  static view_name = 'BaseWidgetView';
  static view_module = MODULE_NAME;
  static view_module_version = MODULE_VERSION;

  static serializers: ISerializers = { ...DOMWidgetModel.serializers };

  // constructor(args: any) {
  //   console.log('args:', args);
  //   super(args.model.attributes, args.model);
  //   // super(model.attributes, model);
  // }

  defaults() {
    return {
      ...super.defaults(),

      _model_name: BaseWidgetModel.model_name,
      _model_module: BaseWidgetModel.model_module,
      _model_module_version: BaseWidgetModel.model_module_version,
      _view_name: BaseWidgetModel.view_name,
      _view_module: BaseWidgetModel.view_module,
      _view_module_version: BaseWidgetModel.view_module_version,

      count: 1
    };
  }
}

export class BaseWidgetView extends DOMWidgetView {
  render() {
    ReactDOM.render(
      <Plot type={this.model.get('type')} widgetView={this} />,
      this.el
    );

    // this.onchangeCount();
    // this.model.on('change:count', this.onchangeCount, this);
  }

  remove() {
    ReactDOM.unmountComponentAtNode(this.el);

    Backbone.View.prototype.remove.apply(this, arguments as any);
  }

  onchangeCount() {
    var old_value = this.model.previous('count');
    var new_value = this.model.get('count');
    this.el.textContent = String(old_value) + ' -> ' + String(new_value);
  }
}
