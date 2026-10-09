import { FeedSource, ModelId, SOURCES } from './sources';

export interface FeedItem {
  id: string;
  model: ModelId;
  title: string;
  link: string;
  source: string;
  summary: string;
  publishedAt: number;
}

const ENTITIES: Record<string, string> = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ',
};

function decode(text: string): string {
  return text
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)))
    .replace(/&([a-z]+);/gi, (m, name) => ENTITIES[name.toLowerCase()] ?? m);
}

function stripHtml(html: string): string {
  return decode(decode(html).replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
}

function tag(block: string, name: string): string {
  const match = block.match(new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, 'i'));
  return match ? match[1].trim() : '';
}

/** Minimal RSS 2.0 / Atom parser — enough for news feeds, no native deps. */
export function parseFeed(xml: string, src: FeedSource): FeedItem[] {
  const blocks = xml.match(/<item[\s>][\s\S]*?<\/item>|<entry[\s>][\s\S]*?<\/entry>/gi) ?? [];
  return blocks.map((block) => {
    let link = decode(tag(block, 'link'));
    if (!link) link = block.match(/<link[^>]*href="([^"]+)"/i)?.[1] ?? '';
    let title = stripHtml(tag(block, 'title'));
    // Google News appends " - Publisher" to titles and puts the publisher in <source>.
    const publisher = stripHtml(tag(block, 'source'));
    if (publisher && title.endsWith(` - ${publisher}`)) {
      title = title.slice(0, -(publisher.length + 3));
    }
    const date = tag(block, 'pubDate') || tag(block, 'published') || tag(block, 'updated');
    const summary = src.url.includes('news.google.com')
      ? ''
      : stripHtml(tag(block, 'description') || tag(block, 'summary') || tag(block, 'content')).slice(0, 220);
    return {
      id: link || title,
      model: src.model,
      title,
      link,
      source: publisher || src.name,
      summary,
      publishedAt: Date.parse(decode(date)) || 0,
    };
  });
}

function normalizeTitle(title: string): string {
  return title.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

export async function fetchAllFeeds(): Promise<{ items: FeedItem[]; failed: string[] }> {
  const failed: string[] = [];
  const results = await Promise.all(
    SOURCES.map(async (src) => {
      try {
        const res = await fetch(src.url, { headers: { Accept: 'application/rss+xml, application/xml, text/xml' } });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return parseFeed(await res.text(), src);
      } catch {
        failed.push(`${src.model}: ${src.name}`);
        return [];
      }
    }),
  );

  const seen = new Set<string>();
  const items = results
    .flat()
    .filter((item) => {
      const key = normalizeTitle(item.title);
      if (!item.title || !item.link || seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .sort((a, b) => b.publishedAt - a.publishedAt);
  return { items, failed };
}

export function timeAgo(ts: number, now = Date.now()): string {
  if (!ts) return '';
  const mins = Math.max(0, Math.round((now - ts) / 60000));
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.round(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(ts).toLocaleDateString();
}
