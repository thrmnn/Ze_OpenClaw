#!/usr/bin/env node
/**
 * Direct Trello API access for Clawdbot
 * Usage: ./trello-query.js <command> [args]
 * Commands: boards, cards <boardId>, card <cardId>
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Load env file manually
const envPath = path.join(__dirname, '../credentials/trello.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
  const match = line.match(/^([^=]+)=(.*)$/);
  if (match) env[match[1].trim()] = match[2].trim();
});

const TRELLO_API_KEY = env.TRELLO_API_KEY;
const TRELLO_API_TOKEN = env.TRELLO_TOKEN || env.TRELLO_API_TOKEN;

if (!TRELLO_API_KEY || !TRELLO_API_TOKEN) {
  console.error('Missing TRELLO_API_KEY or TRELLO_TOKEN in credentials/trello.env');
  process.exit(1);
}

function apiGet(path) {
  return new Promise((resolve, reject) => {
    const url = `https://api.trello.com/1${path}${path.includes('?') ? '&' : '?'}key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function main() {
  const [,, command, ...args] = process.argv;

  try {
    switch (command) {
      case 'boards': {
        const boards = await apiGet('/members/me/boards?filter=open&fields=name,id,url');
        console.log(JSON.stringify(boards, null, 2));
        break;
      }
      case 'cards': {
        const boardId = args[0];
        if (!boardId) throw new Error('Missing boardId');
        const cards = await apiGet(`/boards/${boardId}/cards?fields=name,id,url,desc,due,labels,idList`);
        console.log(JSON.stringify(cards, null, 2));
        break;
      }
      case 'card': {
        const cardId = args[0];
        if (!cardId) throw new Error('Missing cardId');
        const card = await apiGet(`/cards/${cardId}?fields=name,id,url,desc,due,labels,idList,idBoard&checklists=all`);
        console.log(JSON.stringify(card, null, 2));
        break;
      }
      case 'lists': {
        const boardId = args[0];
        if (!boardId) throw new Error('Missing boardId');
        const lists = await apiGet(`/boards/${boardId}/lists?fields=name,id`);
        console.log(JSON.stringify(lists, null, 2));
        break;
      }
      default:
        console.error('Unknown command. Available: boards, cards <boardId>, card <cardId>, lists <boardId>');
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();
