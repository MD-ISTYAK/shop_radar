const fs = require('fs');
const path = require('path');

// .docx is a zip file - we'll use the built-in zlib
const { execSync } = require('child_process');

// Use PowerShell's .NET capabilities to extract text from docx
const docxPath = path.resolve(__dirname, '..', 'ShopRadar_SocialModule_TechSpec.docx');

// docx is a zip, extract word/document.xml
const AdmZip = require('adm-zip');
const zip = new AdmZip(docxPath);
const entry = zip.getEntry('word/document.xml');
const content = entry.getData().toString('utf8');

// Strip XML tags and clean up whitespace
const text = content
  .replace(/<w:p[^>]*\/>/g, '\n')  // self-closing paragraphs = newline
  .replace(/<w:p[^>]*>/g, '\n')     // paragraph start = newline
  .replace(/<w:tab\/>/g, '\t')      // tabs
  .replace(/<w:br\/>/g, '\n')       // line breaks
  .replace(/<[^>]+>/g, '')          // strip all remaining XML tags
  .replace(/&amp;/g, '&')
  .replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"')
  .replace(/&apos;/g, "'")
  .replace(/\n{3,}/g, '\n\n')       // collapse multiple newlines
  .trim();

console.log(text);
