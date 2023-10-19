import { Modal } from '@arco-design/web-react';
import React, { ReactNode, useState } from 'react';

import { PlotResponse } from '../Plot';

export default function RunLogModal({
  plotResponse,
  render
}: {
  plotResponse?: PlotResponse;
  render(open: () => void): ReactNode;
}) {
  const [visible, setVisible] = useState(false);

  return (
    <>
      {render(() => setVisible(true))}

      <Modal
        title="查看执行日志"
        visible={visible}
        hideCancel
        okText="关闭"
        onOk={() => {
          setVisible(false);
        }}
        escToExit={false}
        maskClosable={false}
        closable={false}
        style={{ width: 1100 }}
      >
        <div style={{ display: 'flex' }}>
          <section style={{ width: '49.5%' }}>
            <h3 style={{ margin: '0 0 12px' }}>stdout 标准输出日志</h3>
            <code
              style={{
                display: 'block',
                height: 400,
                overflow: 'auto',
                padding: 4,
                borderRadius: 4,
                backgroundColor: '#f3f3f3',
                whiteSpace: 'pre-wrap'
              }}
            >
              {plotResponse?.response.extra.stdout}
            </code>
          </section>
          <div style={{ width: '1%' }}></div>
          <section style={{ width: '49.5%' }}>
            <h3 style={{ margin: '0 0 12px' }}>stderr 标准错误日志</h3>
            <code
              style={{
                display: 'block',
                height: 400,
                overflow: 'auto',
                padding: 4,
                borderRadius: 4,
                backgroundColor: '#ffe7e7',
                whiteSpace: 'pre-wrap'
              }}
            >
              {plotResponse?.response.extra.stderr}
            </code>
          </section>
        </div>
      </Modal>
    </>
  );
}
