import { CSSProperties, Fragment, useMemo } from 'react';

import { Link } from '@arco-design/web-react';
import React from 'react';

export default function FileBreadcrumbs({
  style,
  path,
  setPath
}: {
  style?: CSSProperties;
  path: string;
  setPath(path: string): void;
}) {
  const items = useMemo(() => {
    return path.split('/').filter(item => Boolean(item));
  }, [path]);

  return (
    <div style={style}>
      {/* <div>{path}</div> */}
      {items.length ? (
        <Link
          onClick={() => {
            setPath('/');
          }}
        >
          全部文件
        </Link>
      ) : (
        <span>全部文件</span>
      )}

      <span className="mx4">/</span>

      {items?.map((item, i) => {
        if (i === items.length - 1) {
          return (
            <span>
              <span>{item}</span>
              <span className="mx4">/</span>
            </span>
          );
        }

        return (
          <Fragment key={i}>
            <Link
              style={{ wordBreak: 'keep-all', wordWrap: 'break-word' }}
              onClick={() => {
                setPath('/' + items.slice(0, i + 1).join('/') + '/');
              }}
            >
              {item}
            </Link>

            <span className="mx4">/</span>
          </Fragment>
        );
      })}
    </div>
  );
}
