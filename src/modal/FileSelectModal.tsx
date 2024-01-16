import { Link, Message, Modal, Table } from '@arco-design/web-react';
import React, { ReactNode, useEffect, useRef, useState } from 'react';

import { IconFile, IconFolder } from '@arco-design/web-react/icon';
import FileBreadcrumbs from '../components/FileBreadcrumbs/FileBreadcrumbs';
import CommRequest from '../util/CommRequest';

interface CommFile {
  name: string;
  is_dir: boolean;
}

export default function FileSelectModal({
  commRequest,
  onOk,
  render,
  initialPath
}: {
  commRequest?: CommRequest;
  render(open: () => void, close: () => void): ReactNode;
  onOk(filePath: string): void;
  initialPath: string;
}) {
  const [visible, setVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const [currentPath, setCurrentPath] = useState('');
  const [commFiles, setCommFiles] = useState<CommFile[]>();

  const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([]);

  function fetchFileList(path?: string) {
    const targetPath = path || currentPath;

    setLoading(true);
    commRequest?.listFiles(targetPath).then(val => {
      if (val.response.status === 'failed') {
        setCommFiles([]);

        Message.error(
          `获取文件列表失败，请检查输入路径 ${targetPath}，确认文件系统访问权限`
        );
        return;
      }

      const sortedFiles = (val.response.result as CommFile[]).sort((a, b) => {
        if (a.is_dir && b.is_dir) {
          if (a.name > b.name) return 1;
          else return -1;
        }

        if (a.is_dir || b.is_dir) {
          if (a.is_dir) {
            return -1;
          } else if (b.is_dir) {
            return 1;
          }
        }

        if (a.name > b.name) return 1;
        else return -1;
      });

      setCommFiles(sortedFiles);
      setLoading(false);
    });
  }

  useEffect(() => {
    if (!visible) return;

    setCurrentPath(initialPath);
    fetchFileList(initialPath);
  }, [visible]);

  return (
    <>
      {render(
        () => setVisible(true),
        () => setVisible(false)
      )}

      <Modal
        title="选择数据文件"
        visible={visible}
        onOk={() => {
          if (!selectedRowKeys.length) {
            Message.error('请选择数据文件');
            return;
          }
          onOk(`${currentPath}${selectedRowKeys[0]}`);
          setVisible(false);
        }}
        onCancel={() => setVisible(false)}
        escToExit={false}
        maskClosable={false}
        closable={false}
      >
        <FileBreadcrumbs
          style={{ marginBottom: 8 }}
          path={currentPath}
          setPath={path => {
            setCurrentPath(path);
            fetchFileList(path);
          }}
        />

        <Table
          loading={loading}
          rowKey="name"
          pagination={{ showTotal: true }}
          size="small"
          style={{ height: 425 }}
          rowSelection={{
            type: 'radio',
            selectedRowKeys,
            onSelect(selected, record) {
              setSelectedRowKeys([record.name]);
            },
            checkboxProps(record) {
              if (record.is_dir) {
                return {
                  disabled: true
                };
              }
              return {};
            }
          }}
          columns={[
            {
              dataIndex: 'name',
              title: '名称',
              render(col, item, index) {
                return item.is_dir ? (
                  <Link
                    style={{ display: 'block' }}
                    onClick={() => {
                      const path = currentPath + item.name + '/';

                      setCurrentPath(path);
                      fetchFileList(path);
                    }}
                  >
                    <IconFolder style={{ marginRight: 4 }} />
                    {col}
                  </Link>
                ) : (
                  <div>
                    <IconFile
                      style={{ marginRight: 4, verticalAlign: 'middle' }}
                    />
                    {col}
                  </div>
                );
              }
            }
          ]}
          data={commFiles}
        />
      </Modal>
    </>
  );
}
