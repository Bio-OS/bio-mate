import { IconBiomateLogo } from '@arco-iconbox/react-biomate';
// import '@arco-design/web-react/dist/css/arco.css';
import { Message } from '@arco-design/web-react';
import { ReactWidget } from '@jupyterlab/apputils';
import { NotebookActions } from '@jupyterlab/notebook';
import { LabIcon } from '@jupyterlab/ui-components';
import React, { ReactNode } from 'react';
import logo from '../style/logo.svg';
import { BioContext } from './context';
import {
  NAMESPACE,
  WIDGET_ID_APP_PANEL,
  advancedPlotApps,
  basicPlotApps
} from './util/consts';

export function initAppPanel() {
  const { app, layoutRestorer, palette } = BioContext;

  // 创建 widget
  const appPanelWidget = new AppPanelWidget();
  appPanelWidget.id = WIDGET_ID_APP_PANEL;
  appPanelWidget.title.icon = new LabIcon({
    name: 'bioMate:logo',
    svgstr: logo
  });
  appPanelWidget.title.caption = 'BIO MATE';

  layoutRestorer.add(appPanelWidget, NAMESPACE);
  app.shell.add(appPanelWidget, 'right', { rank: 501 });

  // Add an application command
  const commandOpenApppanel: string = 'bio-mate:openAppPanel';
  app.commands.addCommand(commandOpenApppanel, {
    icon: new LabIcon({
      name: 'bioMate:logo',
      svgstr: logo
    }),
    label: 'Toggle App Panel',
    execute: async () => {
      if (appPanelWidget.isVisible) {
        app.shell.collapseRight();
      } else {
        // Activate the widget
        app.shell.activateById(appPanelWidget.id);
      }
    }
  });
  palette.addItem({ command: commandOpenApppanel, category: 'BIO MATE' });

  // const tracker = new WidgetTracker({ namespace: 'bioMateAppPanel' });

  // if (!tracker.has(appPanelWidget)) {
  //   tracker.add(appPanelWidget);
  // }

  // if (restorer) {
  //   if (restorer) restorer.add(tool_browser, NAMESPACE);

  //   restorer.restore(tracker, {
  //     name: () => 'bioMate:appPanel',
  //     command: commandOpenApppanel
  //   });
  // }
}

export class AppPanelWidget extends ReactWidget {
  render() {
    return <AppPanel />;
  }
}

function AppPanel() {
  return (
    <div style={{ backgroundColor: 'white', height: '100%' }}>
      <div style={{ padding: '16px 20px', display: 'flex' }}>
        <IconBiomateLogo style={{ width: 100, height: 20 }} />
      </div>

      <PanelSection title="基础绘图工具" apps={basicPlotApps} />
      <PanelSection title="高级进阶工具" apps={advancedPlotApps} />
    </div>
  );
}

function PanelSection({
  title,
  apps
}: {
  title: ReactNode;
  apps: typeof basicPlotApps;
}) {
  return (
    <section
      style={{
        padding: '16px 24px'
      }}
    >
      <div style={{ color: '#737A87', marginBottom: 16 }}>{title}</div>

      <div
        style={{
          display: 'grid',
          gap: '16px 8px',
          gridTemplateColumns: 'repeat(auto-fill, minmax(60px, 1fr))',
          gridAutoFlow: 'dense'
        }}
      >
        {apps.map(({ name, icon: Icon, color, id }) => {
          return (
            <div
              key={name}
              className="bioMateIconWrapper"
              onClick={() => {
                const currentWidget = BioContext.notebookTracker.currentWidget;
                const notebook = currentWidget?.content;
                let cell = BioContext.notebookTracker.activeCell;

                if (!notebook || !notebook.isVisible || !cell) {
                  Message.error('请先选择或者创建目标 Notebook 文档');
                  return;
                }

                if (!id) {
                  Message.error(`暂未实现: ${name}`);
                  return;
                }

                const code = `bio_mate.plot(type="${id}")`;

                if (
                  cell.model.sharedModel.cell_type !== 'code' ||
                  cell.model.sharedModel.source
                ) {
                  NotebookActions.insertBelow(notebook);

                  cell = BioContext.notebookTracker.activeCell;
                  if (!cell) return;
                }

                cell.model.metadata.set('BioMate', true);

                cell.model.sharedModel.setSource(code);
                NotebookActions.run(
                  notebook,
                  currentWidget.context.sessionContext
                );
              }}
            >
              <div className="bioMateIconContainer">
                <Icon style={{ color, fontSize: 20 }} />
              </div>
              <div>{name}</div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
