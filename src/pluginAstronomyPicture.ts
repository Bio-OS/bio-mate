import { ILayoutRestorer, JupyterFrontEnd } from '@jupyterlab/application';
import {
  ICommandPalette,
  MainAreaWidget,
  WidgetTracker
} from '@jupyterlab/apputils';
import { Widget } from '@lumino/widgets';

interface APODResponse {
  copyright: string;
  date: string;
  explanation: string;
  media_type: 'video' | 'image';
  title: string;
  url: string;
}

/**
 * Astronomy Picture of the Day
 * @param app
 * @param palette
 */
export default async function activatePluginApod(
  app: JupyterFrontEnd,
  palette: ICommandPalette,
  restorer: ILayoutRestorer
) {
  console.log(
    `JupyterLab extension bio-mate:apod v3 is activated! (JupyterLab: ${app.version})`
  );

  const tracker = new WidgetTracker({ namespace: 'bioMate' });

  function newWidget() {
    const content = new ApodWidget();
    const mainAreaWidget = new MainAreaWidget({ content });
    mainAreaWidget.id = 'bioMate-apod-jupyterlab';
    mainAreaWidget.title.label = 'Astronomy Picture';
    mainAreaWidget.title.closable = true;

    return mainAreaWidget;
  }

  let widget = newWidget();

  // Add an application command
  const command: string = 'bioMate:openApod';
  app.commands.addCommand(command, {
    label: 'Random Astronomy Picture',
    execute: async () => {
      if (widget.isDisposed) {
        // Regenerate the widget if disposed
        widget = newWidget();
      }
      if (!widget.isAttached) {
        // Attach the widget to the main work area if it's not there
        app.shell.add(widget, 'main');
      }

      if (!tracker.has(widget)) {
        tracker.add(widget);
      }

      // 每次执行command，即更新图片
      await widget.content.updatePicture();

      // Activate the widget
      app.shell.activateById(widget.id);
    }
  });

  // Add the command to the palette.
  palette.addItem({ command, category: 'Tutorial' });

  if (restorer) {
    restorer.restore(tracker, {
      name: () => 'bioMate',
      command
    });
  }
}

class ApodWidget extends Widget {
  pTitle: HTMLElement;
  img: HTMLImageElement;
  pDescription: HTMLElement;

  constructor() {
    super();

    this.addClass('bioMateWidget');

    this.pTitle = document.createElement('p');
    this.img = document.createElement('img');
    this.pDescription = document.createElement('p');

    this.img.style.width = '90%';
    this.pDescription.style.width = '80%';

    this.node.append(this.pTitle, this.img, this.pDescription);
  }

  async updatePicture() {
    // Fetch info about a random picture
    const response = await fetch(
      `https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=${this.randomDate()}`
    );
    const data = (await response.json()) as APODResponse;

    if (data.media_type === 'image') {
      // Populate the image
      this.img.src = data.url;
      this.img.title = data.title;

      this.pTitle.textContent = `${data.date}: ${data.title}`;
      this.pDescription.textContent = data.explanation;
    } else {
      this.img.title = 'Random APOD was not a picture.';
      this.img.src = '';
      this.img.title = '';
      this.pTitle.textContent = '';
    }
  }

  // Get a random date string in YYYY-MM-DD format
  randomDate() {
    const start = new Date(2010, 1, 1);
    const end = new Date();
    const randomDate = new Date(
      start.getTime() + Math.random() * (end.getTime() - start.getTime())
    );
    return randomDate.toISOString().slice(0, 10);
  }
}
