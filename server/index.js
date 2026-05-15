// Very 1st script of node js
console.log('');
console.log("******* Face Trace Server Side *******");
console.log('');
require('dotenv').config();

// Internal Packages
const express = require('express');
const mongoose = require('mongoose');
const axios = require('axios');
const cloudinary = require('cloudinary').v2;

// Routes
const authRouter = require('./routes/auth.js');

// INIT
const app = express();
const PORT = process.env.PORT || 9000;
const DB = process.env.MONGO_URI;

// Middleware
app.use(express.json());
app.use(authRouter);

// ─────────────────────────────────────────────────────────────────────────────
//  CLOUDINARY CONFIGURATION
//  Add these to your .env file:
//    CLOUDINARY_CLOUD_NAME=your_cloud_name
//    CLOUDINARY_API_KEY=your_api_key
//    CLOUDINARY_API_SECRET=your_api_secret
// ─────────────────────────────────────────────────────────────────────────────
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Helper function to upload base64 to Cloudinary
async function uploadToCloudinary(base64Image, folder = 'facetrace') {
  try {
    // Upload base64 image to Cloudinary
    const result = await cloudinary.uploader.upload(`data:image/png;base64,${base64Image}`, {
      folder: folder,
      transformation: [
        { quality: 'auto' },
        { fetch_format: 'auto' }
      ]
    });
    
    console.log(`✅ Uploaded to Cloudinary: ${result.secure_url}`);
    return result.secure_url;
  } catch (error) {
    console.error('❌ Cloudinary upload error:', error.message);
    throw new Error('Failed to upload image to Cloudinary');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HELPER: callImageAPI(prompt, size)
//
//  Tries model list in order; first success wins.
//  GPT Image models return base64 PNG → uploaded to Cloudinary
//  Falls back gracefully if a model isn't on your account tier.
// ═══════════════════════════════════════════════════════════════════════════════

// Try models in this order
const IMAGE_MODELS = ['gpt-image-1', 'gpt-image-1.5', 'gpt-image-2'];

// GPT Image models support different sizes than DALL-E
function mapSize(size) {
  const map = {
    '1024x1024': '1024x1024',
    '1792x1024': '1536x1024',  // closest landscape equivalent
    '1024x1792': '1024x1536',  // closest portrait equivalent
  };
  return map[size] || '1024x1024';
}

async function callImageAPI(prompt, size = '1024x1024', type = 'general') {
  const OPENAI_KEY = process.env.OPENAI_API_KEY;
  if (!OPENAI_KEY) throw new Error('OPENAI_API_KEY is not set in .env file');

  const imageSize = mapSize(size);
  let lastError;

  for (const model of IMAGE_MODELS) {
    try {
      console.log(`\n🎨 Trying model : Python Image Generation Model`);
      console.log(`📐 Size         : ${imageSize}`);
      console.log(`📝 Prompt       : ${prompt.substring(0, 100)}…`);

      // Build request body based on model type
      const requestBody = {
        model,
        prompt,
        n: 1,
        size: imageSize,
      };

      // Only add quality parameter for DALL-E models, not GPT image models
      if (!model.includes('gpt-image')) {
        requestBody.quality = 'standard';
      }

      const response = await axios.post(
        'https://api.openai.com/v1/images/generations',
        requestBody,
        {
          headers: {
            Authorization: `Bearer ${OPENAI_KEY}`,
            'Content-Type': 'application/json',
          },
          timeout: 120_000,  // 2 minutes
        }
      );

      const item = response.data?.data?.[0];
      if (!item) throw new Error('Empty data array in OpenAI response');

      // ── Model returned a hosted URL directly ──────────────────────────────
      if (item.url) {
        console.log(`✅ [${model}] Got hosted URL`);
        return item.url;
      }

      // ── Model returned base64 (default for gpt-image-1/1.5/2) ────────────
      if (item.b64_json) {
        const folder = type === 'sketch' ? 'facetrace/sketches' : 'facetrace/general';
        const imageUrl = await uploadToCloudinary(item.b64_json, folder);
        console.log(`✅ [${model}] Uploaded to Cloudinary → ${imageUrl}`);
        return imageUrl;
      }

      throw new Error('Response contained neither url nor b64_json');

    } catch (err) {
      const status  = err.response?.status;
      const message = err.response?.data?.error?.message || err.message || '';
      console.error(`❌ [${model}] HTTP ${status ?? 'N/A'}: ${message}`);

      // Model not on account / deprecated → try next
      if (
        status === 404 ||
        message.toLowerCase().includes('does not exist') ||
        message.toLowerCase().includes('unknown model') ||
        (status === 400 && message.toLowerCase().includes('unknown parameter'))
      ) {
        lastError = new Error(`${model}: ${message}`);
        continue;
      }

      // Rate limit / auth / content policy → surface immediately
      throw err;
    }
  }

  throw lastError || new Error('All image models failed. Check your OpenAI plan and API key.');
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ROUTE 1: General Image Generation
//  POST /api/generate-image
//  Body: { prompt: string, size?: string }
// ═══════════════════════════════════════════════════════════════════════════════
app.post('/api/generate-image', async (req, res) => {
  try {
    console.log('\n📨 POST /api/generate-image');
    const { prompt, size } = req.body;

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return res.status(400).json({
        success: false,
        error: 'prompt is required and must be a non-empty string',
      });
    }
    if (prompt.trim().length > 4000) {
      return res.status(400).json({
        success: false,
        error: 'prompt must be less than 4000 characters',
      });
    }

    const imageUrl = await callImageAPI(prompt.trim(), size, 'general');
    return res.status(200).json({
      success: true,
      imageUrl,
      message: 'Image generated successfully',
    });

  } catch (err) {
    console.error('❌ /api/generate-image error:', err.message);
    if (err.code === 'ECONNABORTED') {
      return res.status(504).json({ success: false, error: 'Request to OpenAI timed out. Please try again.' });
    }
    const status   = err.response?.status  ?? 500;
    const errorMsg = err.response?.data?.error?.message || err.message || 'Internal server error';
    return res.status(status).json({ success: false, error: errorMsg });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ROUTE 2: Criminal Sketch Generation
//  POST /api/generate-sketch
//  Body: { attributes?: object, description?: string, additionalPrompt?: string }
// ═══════════════════════════════════════════════════════════════════════════════
app.post('/api/generate-sketch', async (req, res) => {
  try {
    console.log('\n📨 POST /api/generate-sketch');
    const { attributes = {}, description = '', additionalPrompt = '' } = req.body;

    // Build the forensic sketch prompt
    const parts = [
      'Create a professional police forensic pencil sketch portrait of a criminal suspect for law enforcement use.',
      'Art style: authentic pencil-on-paper forensic composite sketch,',
      'black and white with realistic cross-hatching and shading,',
      'proportionally accurate, professional law enforcement composite art.',
      'Show only the face and head portrait. No body. Plain white background.',
    ];

    const attrMap = {
      gender:       'Gender',
      ageGroup:     'Approximate age',
      ethnicity:    'Ethnicity',
      complexion:   'Skin complexion',
      build:        'Build',
      hairColor:    'Hair color',
      hairStyle:    'Hair style',
      expression:   'Facial expression',
      glasses:      'Eyewear',
      headCovering: 'Head covering',
      faceShape:    'Face shape',
      eyes:         'Eyes',
      eyeColor:     'Eye color',
      nose:         'Nose',
      ears:         'Ears',
      lips:         'Mouth/Lips',
      eyebrows:     'Eyebrows',
      jaw:          'Jaw/Chin',
      forehead:     'Forehead',
      cheekbones:   'Cheekbones',
      facialHair:   'Facial hair',
      scarsMarks:   'Scars/Marks',
      skinTexture:  'Skin texture',
    };

    for (const [key, label] of Object.entries(attrMap)) {
      const val = attributes[key];
      if (val && String(val).trim()) {
        parts.push(`${label}: ${String(val).trim()}.`);
      }
    }

    if (description?.trim())      parts.push(`Witness description: ${description.trim()}.`);
    if (additionalPrompt?.trim()) parts.push(`Additional details: ${additionalPrompt.trim()}.`);
    parts.push('Make it look exactly like an official police composite sketch used in real criminal investigations.');

    const finalPrompt = parts.join(' ');
    console.log(`📝 Built prompt (${finalPrompt.length} chars)`);

    if (finalPrompt.length > 4000) {
      return res.status(400).json({
        success: false,
        error: 'Combined prompt is too long. Please reduce descriptions.',
      });
    }

    const imageUrl = await callImageAPI(finalPrompt, '1024x1024', 'sketch');
    return res.status(200).json({
      success: true,
      imageUrl,
      promptUsed: finalPrompt,
      message: 'Forensic sketch generated successfully',
    });

  } catch (err) {
    console.error('❌ /api/generate-sketch error:', err.message);
    if (err.code === 'ECONNABORTED') {
      return res.status(504).json({ success: false, error: 'Request timed out. Please try again.' });
    }
    const status   = err.response?.status  ?? 500;
    const errorMsg = err.response?.data?.error?.message || err.message || 'Internal server error';
    return res.status(status).json({ success: false, error: errorMsg });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ROUTE 3: Health Check  GET /api/health
// ═══════════════════════════════════════════════════════════════════════════════
app.get('/api/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'FaceTrace API is running',
    timestamp: new Date().toISOString(),
    openaiConfigured: !!process.env.OPENAI_API_KEY,
    cloudinaryConfigured: !!(process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY),
    modelsToTry: IMAGE_MODELS,
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
//  DATABASE & SERVER START
// ═══════════════════════════════════════════════════════════════════════════════
mongoose
  .connect(DB)
  .then(() => console.log('✅ MongoDB connection successful'))
  .catch((e) => console.log('❌ MongoDB error:', e.message));

// For Vercel serverless deployment, export the app
if (process.env.VERCEL) {
  module.exports = app;
} else {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`📡 Health  : GET  http://localhost:${PORT}/api/health`);
    console.log(`🎨 Image   : POST http://localhost:${PORT}/api/generate-image`);
    console.log(`🖼️  Sketch  : POST http://localhost:${PORT}/api/generate-sketch`);
    console.log('');
  });
}