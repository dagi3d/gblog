import { Client } from "@notionhq/client";
import { NotionConverter } from "notion-to-md";
import { NotionRenderer, createBlockRenderer } from '@notion-render/client';
import dotenv from 'dotenv'
import slugify from 'slugify'
import * as path from 'path';
import { readFile } from 'fs/promises';



dotenv.config({ path: '.env.local' })
dotenv.config({ path: '.env' })

const notion = new Client({ auth: process.env.NOTION_API_KEY });
const DATA_SOURCE_ID = process.env.NOTION_DATA_SOURCE_ID;

const MEDIA_OUTPUT_DIR = './public/static/img';
const MEDIA_MANIFEST_DIR = './.notion-to-md/media';

// notion-to-md's DownloadStrategy keys its manifest entries by block id and
// records the local path each image/video/file block was downloaded to.
// We reuse that manifest so NotionRenderer's HTML output can point at the
// downloaded copy instead of Notion's temporary, expiring S3 URLs.
const loadMediaManifest = async (pageId) => {
  try {
    const raw = await readFile(`${MEDIA_MANIFEST_DIR}/${pageId}_media.json`, 'utf-8');
    const { mediaEntries } = JSON.parse(raw);
    return new Map(
      Object.entries(mediaEntries ?? {}).map(([blockId, entry]) => [blockId, entry.mediaInfo.transformedPath])
    );
  } catch {
    return new Map();
  }
}

const createImageBlockRenderer = (mediaManifest) => createBlockRenderer('image', async (data, renderer) => {
  const notionSrc = 'file' in data.image ? data.image.file.url : data.image.external.url;
  const src = mediaManifest.get(data.id) ?? notionSrc;
  return `
    <figure class="notion-${data.type}">
      <img src="${src}" />
      ${data.image.caption.length > 0
      ? `<legend>${await renderer.render(...data.image.caption)}</legend>`
      : ''}
    </figure>
  `;
});

export const load_posts = async () => {
  const pages = await notion.dataSources.query({ data_source_id: DATA_SOURCE_ID })
  return await Promise.all(pages.results.map(async (page) => {
    const { status, tags, excerpt: excerptProperty, } = page.properties;

    const n2m = new NotionConverter(notion).downloadMediaTo({
      outputDir: MEDIA_OUTPUT_DIR,
      transformPath: (localPath) => `/static/img/${path.basename(localPath)}`,
    })

    const originalDebug = console.debug;
    console.debug = () => { };
    try {
      await n2m.convert(page.id);
    } finally {
      console.debug = originalDebug;
    }

    const mediaManifest = await loadMediaManifest(page.id);
    const renderer = new NotionRenderer({
      client: notion,
      renderers: [createImageBlockRenderer(mediaManifest)],
    });
    const { results: blocks } = await notion.blocks.children.list({ block_id: page.id });

    const content = await renderer.render(...blocks);

    const title = page.properties.title['title'][0].plain_text;
    const published_at = page.properties.published_at.date.start;
    const urlPath = "/" + published_at.replaceAll("-", "/") + "/" + slugify(title, { lower: true, strict: true });

    const excerpt = excerptProperty['rich_text'].map((text) => text.plain_text).join("");

    return {
      title,
      status: status['status'].name,
      path: urlPath,
      tags: tags['multi_select'].map((tag) => tag.name),
      published_at,
      content,
      excerpt,
    }
  }));
}

