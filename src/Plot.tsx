import {
  Button,
  Form,
  Grid,
  Input,
  InputNumber,
  Message,
  Select,
  Spin,
  Switch,
  Tabs,
  Tooltip
} from '@arco-design/web-react';
import {
  IconCheck,
  IconClose,
  IconCommon,
  IconMinus,
  IconPlus,
  IconQuestionCircle,
  IconUpload
} from '@arco-design/web-react/icon';
import { Cell } from '@jupyterlab/cells';
import _ from 'lodash';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { BaseWidgetView } from './basewidget';
import FileSelectModal from './modal/FileSelectModal';
import RunLogModal from './modal/RunLogModal';
import CommRequest, {
  CommResponse,
  CommResponseInner
} from './util/CommRequest';
import { basicPlotApps } from './util/consts';

export interface PlotResponse extends CommResponse {
  response: CommResponseInner & {
    extra: {
      stdout: string;
      stderr: string;
    };
  };
}

const BIO_MATE_PLOT_CONFIG = 'bioMatePlotConfig';

export default function Plot({
  type,
  widgetView
}: {
  type: string;
  widgetView: BaseWidgetView;
}) {
  const all_defs = widgetView.model.attributes.all_defs;
  const plotInfo = all_defs[type];

  const { data, input, meta, ui, sample_data_file } = plotInfo;

  const [plotResponse, setPlotResponse] = useState<PlotResponse>();
  const [generating, setGenerating] = useState(false);
  const [min, setMin] = useState(false);
  const [imgSample, setImgSample] = useState('');
  const [imgPlot, setImgPlot] = useState('');
  const refRequest = useRef<CommRequest>();

  const [formDataFiles] = Form.useForm();
  const [formDataParams] = Form.useForm();
  const [formPlotParams] = Form.useForm();
  const [formCommonParams] = Form.useForm();

  const Icon = useMemo(() => {
    const app = basicPlotApps.find(item => item.id === type);
    return app?.icon || IconCommon;
  }, []);

  const initialValues = useMemo(() => {
    return {
      ...input,
      dataFile: { dataFilePath: sample_data_file }
    };
  }, []);

  useEffect(() => {
    const cell = _.get(
      widgetView,
      'pWidget.parent.parent.parent.parent.parent'
    ) as Cell | undefined;
    const plotConfig = cell?.model.metadata.get(BIO_MATE_PLOT_CONFIG) as {
      [key: string]: any;
    };

    const values = plotConfig || initialValues;

    formDataFiles.setFieldsValue(values.dataFile);
    formDataParams.setFieldsValue(values.columns);
    formPlotParams.setFieldsValue(values.plot_settings);
    formCommonParams.setFieldsValue(values.general);
  }, []);

  useEffect(() => {
    refRequest.current = new CommRequest({ widgetView });
    refRequest.current?.getSampleImage().then(val => {
      if (val.response.status === 'failed') {
        Message.error(`获取样例图片失败: ${val.response.msg}`);
        return;
      }

      setImgSample(val.response.result);
    });

    // this.model.on('msg:custom', this.handle_message.bind(this));

    // widgetView.on('msg:custom', () => {
    //   console.log('msg:custom');
    // });
    // widgetView.model.on('msg:custom', v => {
    //   console.log('msg:custom', v);
    // });
  }, []);

  if (!type || !all_defs)
    return (
      <div
        style={{ padding: '4px 0px', display: 'flex', alignItems: 'center' }}
      >
        <div>BIO MATE: type is required. Please reference the code </div>
        <code
          style={{
            marginLeft: 6,
            backgroundColor: 'lightgrey',
            padding: '2px 4px',
            borderRadius: 3
          }}
        >
          bio_mate.plot(type="volcano")
        </code>
      </div>
    );

  return (
    <>
      <section>
        <header
          style={{
            padding: '5px 16px',
            color: 'white',
            fontWeight: 500,
            borderRadius: min ? 4 : '4px 4px 0px 0px',
            background: 'var(--light-primary-primary-6, #1664FF)',
            display: 'flex',
            justifyContent: 'space-between'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Icon style={{ marginRight: 4 }} />
            <span>{plotInfo.meta.name.zh_cn}</span>
          </div>

          <div>
            {min ? (
              <Button
                size="mini"
                icon={<IconPlus />}
                onClick={() => setMin(false)}
              />
            ) : (
              <Button
                size="mini"
                icon={<IconMinus />}
                onClick={() => setMin(true)}
              />
            )}
          </div>
        </header>

        <main
          style={{
            padding: '24px 32px 0',
            borderLeft: '1px solid lightgrey',
            borderRight: '1px solid lightgrey',
            display: min ? 'none' : 'flex'
          }}
        >
          <div
            style={{
              flex: 1,
              marginRight: 6,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            <img
              src={imgSample}
              style={{
                maxWidth: '100%',
                maxHeight: 340,
                padding: 4,
                border: '1px solid #EAEDF1',
                // boxShadow: '0 0 5px 1px lightgrey',
                boxShadow: '0 3px 20px 0px #0001',
                borderRadius: 8,
                boxSizing: 'border-box'
              }}
            />
          </div>

          <Tabs style={{ flex: 2 }}>
            <Tabs.TabPane
              title="数据文件"
              key="data"
              style={{ paddingRight: 12, height: 280, overflow: 'auto' }}
            >
              <Form form={formDataFiles}>
                <Form.Item
                  label="数据文件"
                  field="dataFilePath"
                  rules={[{ required: true }]}
                >
                  {(val, form) => {
                    return (
                      <>
                        <div style={{ marginBottom: 16 }}>
                          <FileSelectModal
                            commRequest={refRequest.current}
                            onOk={filePath => {
                              form.setFieldValue('dataFilePath', filePath);
                            }}
                            render={(open, close) => {
                              return (
                                <Button icon={<IconUpload />} onClick={open}>
                                  选择文件
                                </Button>
                              );
                            }}
                          />
                        </div>
                        <div>
                          <Input value={val.dataFilePath} disabled />
                        </div>
                      </>
                    );
                  }}
                </Form.Item>
              </Form>
            </Tabs.TabPane>
            <Tabs.TabPane
              title="数据参数"
              key="dataArg"
              style={{ paddingRight: 12, height: 280, overflow: 'auto' }}
            >
              <Form form={formDataParams}>{genFormItem(ui.columns)}</Form>
            </Tabs.TabPane>
            <Tabs.TabPane
              title="绘图参数"
              key="extra"
              style={{ paddingRight: 12, height: 280, overflow: 'auto' }}
            >
              <Form form={formPlotParams}>{genFormItem(ui.plot_settings)}</Form>
            </Tabs.TabPane>
            <Tabs.TabPane
              title="通用参数"
              key="common"
              style={{ paddingRight: 12, height: 280, overflow: 'auto' }}
            >
              <Form form={formCommonParams}>{genFormItem(ui.general)}</Form>
            </Tabs.TabPane>
          </Tabs>
        </main>

        <footer
          style={{
            border: '1px solid lightgrey',
            borderTop: 'unset',
            borderRadius: '0 0 8px 8px',
            padding: '20px 32px',
            display: min ? 'none' : 'flex',
            justifyContent: 'space-between'
          }}
        >
          <div>
            <RunLogModal
              plotResponse={plotResponse}
              render={open => {
                const disabled = !plotResponse || generating;
                const ok = plotResponse?.response.status === 'ok';

                return (
                  <Button
                    onClick={open}
                    disabled={disabled}
                    icon={
                      ok ? (
                        <IconCheck />
                      ) : plotResponse ? (
                        <IconClose />
                      ) : undefined
                    }
                    status={
                      ok ? 'success' : plotResponse ? 'danger' : undefined
                    }
                  >
                    查看执行日志
                  </Button>
                );
              }}
            />
          </div>
          <div>
            <Button
              style={{ marginRight: 12 }}
              onClick={() => {
                formDataFiles.setFieldsValue(initialValues.dataFile);
                formDataParams.setFieldsValue(initialValues.columns);
                formPlotParams.setFieldsValue(initialValues.plot_settings);
                formCommonParams.setFieldsValue(initialValues.general);

                Message.info('已重置各项参数配置到默认值');
              }}
            >
              重置
            </Button>
            <Button
              loading={generating}
              type="primary"
              onClick={async () => {
                await formDataFiles.validate().catch(err => {
                  Message.error('表单配置校验失败，请检查 数据文件 表单');
                  throw err;
                });
                await formDataParams.validate().catch(err => {
                  Message.error('表单配置校验失败，请检查 数据参数 表单');
                  throw err;
                });
                await formPlotParams.validate().catch(err => {
                  Message.error('表单配置校验失败，请检查 绘图参数 表单');
                  throw err;
                });
                await formCommonParams.validate().catch(err => {
                  Message.error('表单配置校验失败，请检查 通用参数 表单');
                  throw err;
                });

                // this.form.validate((errors, values) => {
                //   console.log(errors, values);
                // });

                const allValues = {
                  dataFile: formDataFiles.getFieldsValue(),
                  columns: {
                    ...input.columns,
                    ...formDataParams.getFieldsValue()
                  },
                  plot_settings: {
                    ...input.plot_settings,
                    ...formPlotParams.getFieldsValue()
                  },
                  general: {
                    ...input.general,
                    ...formCommonParams.getFieldsValue()
                  }
                };

                console.log('allValues:', allValues);
                const cell = _.get(
                  widgetView,
                  'pWidget.parent.parent.parent.parent.parent'
                ) as Cell | undefined;
                cell?.model.metadata.set(BIO_MATE_PLOT_CONFIG, allValues);

                setGenerating(true);
                refRequest.current?.genPlot(allValues).then(val => {
                  setGenerating(false);
                  setPlotResponse(val as PlotResponse);

                  if (val.response.status === 'failed') {
                    Message.error(
                      `生成图片失败: ${val.response.msg}。请点击 查看执行日志 获取详情。`
                    );
                    setImgPlot('');
                    return;
                  }

                  Message.success(`生成图片成功`);
                  setImgPlot(val.response.result);
                });
              }}
            >
              生成
            </Button>
          </div>
        </footer>
      </section>

      {Boolean(imgPlot) && (
        <Spin loading={generating} style={{ padding: '12px 0' }}>
          <img
            src={imgPlot}
            style={{
              display: 'block',
              margin: '0 auto',
              maxWidth: '80%',
              padding: 6,
              border: '1px solid #EAEDF1',
              boxShadow: '0 3px 20px 0px #0001',
              borderRadius: 8
            }}
          />
        </Spin>
      )}
    </>
  );
}

function genFormItem(itemDefArr: any[]) {
  if (!itemDefArr) return;

  return itemDefArr.map(item => {
    const typeArr = item.type.split('.');

    const flagGroup = typeArr.length > 1;
    const type = typeArr[0];
    const count = parseInt(typeArr[1]);

    const label = (
      <>
        <span>{item.label}</span>
        {item.help ? (
          <Tooltip content={item.help}>
            <IconQuestionCircle
              style={{
                padding: '4px 0px 7px 4px',
                verticalAlign: 'middle',
                cursor: 'pointer'
              }}
            />
          </Tooltip>
        ) : undefined}
      </>
    );

    function getInputItem() {
      return item.type.startsWith('input') ? (
        <Input placeholder={item.placeholder} />
      ) : item.type.startsWith('switch') ? (
        <Switch />
      ) : item.type.startsWith('number') ? (
        <InputNumber />
      ) : item.type.startsWith('select') ? (
        <Select options={item.options} />
      ) : item.type.startsWith('comma_number') ? (
        <Input placeholder={item.placeholder} />
      ) : undefined;
    }

    if (flagGroup) {
      return (
        <Form.Item label={label}>
          <Grid.Row gutter={8}>
            {[...Array(count)].map((_, index) => {
              return (
                <Grid.Col key={index} span={24 / count}>
                  <Form.Item
                    noStyle
                    field={`${item.key}[${index}]`}
                    rules={item.required ? [{ required: true }] : undefined}
                    triggerPropName={
                      item.type.startsWith('switch') ? 'checked' : undefined
                    }
                  >
                    {getInputItem()}
                  </Form.Item>
                </Grid.Col>
              );
            })}
          </Grid.Row>
        </Form.Item>
      );
    }

    return (
      <Form.Item
        field={item.key}
        label={label}
        rules={
          item.required ? [{ required: true, message: '不能为空' }] : undefined
        }
        triggerPropName={item.type === 'switch' ? 'checked' : undefined}
        normalize={
          item.type === 'comma_number'
            ? val => {
                return val.split(',').map((item: string) => item.trim());
              }
            : undefined
        }
      >
        {getInputItem()}
      </Form.Item>
    );
  });
}
