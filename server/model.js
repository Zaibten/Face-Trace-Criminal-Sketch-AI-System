const express = require('express');
const router = express.Router();

// Import the model utilities from the main server file
// Adjust the path based on your folder structure
const path = require('path');
const modelPath = path.join(__dirname, '../assets/model');
const modelModule = require(modelPath);

// Extract the callImageAPI function and other needed utilities
// Since the original file doesn't export anything, we need to access the functions
// Alternatively, we can redefine the needed functions here

// Helper function to upload to Cloudinary (if needed)
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary (use same env vars as main server)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function uploadToCloudinary(base64Image, folder = 'facetrace/sketches') {
  try {
    const result = await cloudinary.uploader.upload(`data:image/png;base64,${base64Image}`, {
      folder: folder,
      transformation: [
        { quality: 'auto' },
        { fetch_format: 'auto' }
      ]
    });
    return result.secure_url;
  } catch (error) {
    console.error('Cloudinary upload error:', error.message);
    throw new Error('Failed to upload image to Cloudinary');
  }
}

// Image generation function (copied from main server)
async function callImageAPI(prompt, size = '1024x1024', type = 'sketch') {
  const OPENAI_KEY = process.env.OPENAI_API_KEY;
  if (!OPENAI_KEY) throw new Error('OPENAI_API_KEY is not set in .env file');

  const axios = require('axios');
  const IMAGE_MODELS = ['gpt-image-1', 'gpt-image-1.5', 'gpt-image-2'];
  
  function mapSize(size) {
    const map = {
      '1024x1024': '1024x1024',
      '1792x1024': '1536x1024',
      '1024x1792': '1024x1536',
    };
    return map[size] || '1024x1024';
  }

  const imageSize = mapSize(size);
  let lastError;

  for (const model of IMAGE_MODELS) {
    try {
      const requestBody = {
        model,
        prompt,
        n: 1,
        size: imageSize,
      };

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
          timeout: 120000,
        }
      );

      const item = response.data?.data?.[0];
      if (!item) throw new Error('Empty data array in OpenAI response');

      if (item.url) {
        return item.url;
      }

      if (item.b64_json) {
        const folder = type === 'sketch' ? 'facetrace/sketches' : 'facetrace/general';
        const imageUrl = await uploadToCloudinary(item.b64_json, folder);
        return imageUrl;
      }

      throw new Error('Response contained neither url nor b64_json');

    } catch (err) {
      const status = err.response?.status;
      const message = err.response?.data?.error?.message || err.message || '';
      console.error(`Model ${model} failed:`, message);

      if (
        status === 404 ||
        message.toLowerCase().includes('does not exist') ||
        message.toLowerCase().includes('unknown model') ||
        (status === 400 && message.toLowerCase().includes('unknown parameter'))
      ) {
        lastError = new Error(`${model}: ${message}`);
        continue;
      }

      throw err;
    }
  }

  throw lastError || new Error('All image models failed.');
}

router.post('/generate-sketch', async (req, res) => {
  try {
    const {
      // Basic Information
      gender,
      age,
      ageRange,
      ethnicity,
      
      // Facial Structure
      faceShape,
      forehead,
      cheekbones,
      jawline,
      chin,
      
      // Eyes
      eyeShape,
      eyeSize,
      eyeSpacing,
      eyeColor,
      eyebrowShape,
      eyebrowThickness,
      
      // Nose
      noseShape,
      noseSize,
      noseBridge,
      
      // Mouth
      lipShape,
      lipSize,
      mouthWidth,
      teeth,
      
      // Ears
      earSize,
      earShape,
      earLobe,
      
      // Hair
      hairColor,
      hairStyle,
      hairLength,
      hairTexture,
      facialHair,
      facialHairStyle,
      
      // Skin
      complexion,
      skinTone,
      skinTexture,
      scars,
      moles,
      freckles,
      wrinkles,
      
      // Distinctive Features
      glasses,
      glassesType,
      hat,
      hatType,
      jewelry,
      tattoos,
      piercings,
      
      // Expression & Demeanor
      expression,
      gazeDirection,
      headTilt,
      
      // Additional Details
      clothing,
      background,
      lighting,
      additionalNotes,
      
      // Quality Parameters
      quality = 'high',
      style = 'forensic',
      resolution = '1024x1024'
    } = req.body;

    // Validate required parameters
    if (!gender && !ethnicity && !faceShape && !hairStyle) {
      return res.status(400).json({
        success: false,
        error: 'At least one facial feature parameter is required'
      });
    }

    // Build comprehensive prompt
    const promptParts = [];
    
    // Base instruction
    promptParts.push('Generate a police forensic composite sketch of a suspect\'s face');
    
    // Style specification
    if (style === 'forensic') {
      promptParts.push('in professional law enforcement pencil sketch style, black and white, realistic cross-hatching, forensic accuracy');
    } else if (style === 'digital') {
      promptParts.push('in digital forensic composite style, grayscale, clean lines, photorealistic');
    } else if (style === 'traditional') {
      promptParts.push('in traditional artist pencil sketch style, soft shading, charcoal texture');
    }
    
    // Demographics
    if (gender) promptParts.push(`Gender: ${gender}`);
    if (age) promptParts.push(`Age: approximately ${age} years old`);
    if (ageRange) promptParts.push(`Age range: ${ageRange}`);
    if (ethnicity) promptParts.push(`Ethnicity: ${ethnicity}`);
    
    // Face shape and structure
    if (faceShape) promptParts.push(`Face shape: ${faceShape}`);
    if (forehead) promptParts.push(`Forehead: ${forehead}`);
    if (cheekbones) promptParts.push(`Cheekbones: ${cheekbones}`);
    if (jawline) promptParts.push(`Jawline: ${jawline}`);
    if (chin) promptParts.push(`Chin: ${chin}`);
    
    // Eyes
    if (eyeShape) promptParts.push(`Eye shape: ${eyeShape}`);
    if (eyeSize) promptParts.push(`Eye size: ${eyeSize}`);
    if (eyeSpacing) promptParts.push(`Eye spacing: ${eyeSpacing}`);
    if (eyeColor) promptParts.push(`Eye color: ${eyeColor}`);
    if (eyebrowShape) promptParts.push(`Eyebrow shape: ${eyebrowShape}`);
    if (eyebrowThickness) promptParts.push(`Eyebrow thickness: ${eyebrowThickness}`);
    
    // Nose
    if (noseShape) promptParts.push(`Nose shape: ${noseShape}`);
    if (noseSize) promptParts.push(`Nose size: ${noseSize}`);
    if (noseBridge) promptParts.push(`Nose bridge: ${noseBridge}`);
    
    // Mouth
    if (lipShape) promptParts.push(`Lip shape: ${lipShape}`);
    if (lipSize) promptParts.push(`Lip size: ${lipSize}`);
    if (mouthWidth) promptParts.push(`Mouth width: ${mouthWidth}`);
    if (teeth) promptParts.push(`Teeth: ${teeth}`);
    
    // Ears
    if (earSize) promptParts.push(`Ear size: ${earSize}`);
    if (earShape) promptParts.push(`Ear shape: ${earShape}`);
    if (earLobe) promptParts.push(`Earlobe: ${earLobe}`);
    
    // Hair
    if (hairColor) promptParts.push(`Hair color: ${hairColor}`);
    if (hairStyle) promptParts.push(`Hair style: ${hairStyle}`);
    if (hairLength) promptParts.push(`Hair length: ${hairLength}`);
    if (hairTexture) promptParts.push(`Hair texture: ${hairTexture}`);
    if (facialHair) promptParts.push(`Facial hair: ${facialHair}`);
    if (facialHairStyle) promptParts.push(`Facial hair style: ${facialHairStyle}`);
    
    // Skin
    if (complexion) promptParts.push(`Complexion: ${complexion}`);
    if (skinTone) promptParts.push(`Skin tone: ${skinTone}`);
    if (skinTexture) promptParts.push(`Skin texture: ${skinTexture}`);
    if (scars) promptParts.push(`Scars: ${scars}`);
    if (moles) promptParts.push(`Moles: ${moles}`);
    if (freckles) promptParts.push(`Freckles: ${freckles}`);
    if (wrinkles) promptParts.push(`Wrinkles: ${wrinkles}`);
    
    // Accessories
    if (glasses) promptParts.push(`Glasses: ${glasses}`);
    if (glassesType) promptParts.push(`Glasses type: ${glassesType}`);
    if (hat) promptParts.push(`Hat: ${hat}`);
    if (hatType) promptParts.push(`Hat type: ${hatType}`);
    if (jewelry) promptParts.push(`Jewelry: ${jewelry}`);
    if (tattoos) promptParts.push(`Tattoos: ${tattoos}`);
    if (piercings) promptParts.push(`Piercings: ${piercings}`);
    
    // Expression
    if (expression) promptParts.push(`Facial expression: ${expression}`);
    if (gazeDirection) promptParts.push(`Gaze direction: ${gazeDirection}`);
    if (headTilt) promptParts.push(`Head tilt: ${headTilt}`);
    
    // Environment
    if (clothing) promptParts.push(`Clothing: ${clothing}`);
    if (background) promptParts.push(`Background: ${background}`);
    if (lighting) promptParts.push(`Lighting: ${lighting}`);
    
    // Additional notes
    if (additionalNotes) promptParts.push(`Additional details: ${additionalNotes}`);
    
    // Quality instruction
    if (quality === 'high') {
      promptParts.push('High detail, professional quality, anatomical accuracy');
    } else if (quality === 'standard') {
      promptParts.push('Standard detail, clear features');
    }
    
    // Composition instruction
    promptParts.push('Face only portrait, front-facing or three-quarter view, centered composition');
    
    const finalPrompt = promptParts.join('. ');
    
    // Check prompt length
    if (finalPrompt.length > 4000) {
      return res.status(400).json({
        success: false,
        error: 'Combined prompt is too long. Please reduce descriptions.'
      });
    }

    // Generate actual sketch using the model
    const imageUrl = await callImageAPI(finalPrompt, resolution, 'sketch');
    
    return res.status(200).json({
      success: true,
      message: 'Sketch generated successfully',
      sketchId: `sketch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      imageUrl: imageUrl,
      parameters: {
        received: {
          gender,
          age,
          ethnicity,
          faceShape,
          eyeShape,
          noseShape,
          lipShape,
          hairStyle,
          hairColor,
          expression,
          quality,
          style,
          resolution
        },
        prompt: finalPrompt,
        timestamp: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('Sketch generation error:', error);
    
    if (error.code === 'ECONNABORTED') {
      return res.status(504).json({
        success: false,
        error: 'Request timed out. Please try again.'
      });
    }
    
    const status = error.response?.status ?? 500;
    const errorMsg = error.response?.data?.error?.message || error.message || 'Internal server error';
    
    return res.status(status).json({
      success: false,
      error: errorMsg
    });
  }
});

router.get('/sketch-status/:id', async (req, res) => {
  const { id } = req.params;
  
  return res.status(200).json({
    success: true,
    sketchId: id,
    status: 'completed',
    result: {
      imageUrl: `https://facetracecloudinary.com/sketches/${id}.png`,
      generatedAt: new Date().toISOString()
    }
  });
});

router.get('/sketch-parameters', async (req, res) => {
  return res.status(200).json({
    success: true,
    parameters: {
      basic: ['gender', 'age', 'ageRange', 'ethnicity'],
      facialStructure: ['faceShape', 'forehead', 'cheekbones', 'jawline', 'chin'],
      eyes: ['eyeShape', 'eyeSize', 'eyeSpacing', 'eyeColor', 'eyebrowShape', 'eyebrowThickness'],
      nose: ['noseShape', 'noseSize', 'noseBridge'],
      mouth: ['lipShape', 'lipSize', 'mouthWidth', 'teeth'],
      ears: ['earSize', 'earShape', 'earLobe'],
      hair: ['hairColor', 'hairStyle', 'hairLength', 'hairTexture', 'facialHair', 'facialHairStyle'],
      skin: ['complexion', 'skinTone', 'skinTexture', 'scars', 'moles', 'freckles', 'wrinkles'],
      accessories: ['glasses', 'glassesType', 'hat', 'hatType', 'jewelry', 'tattoos', 'piercings'],
      expression: ['expression', 'gazeDirection', 'headTilt'],
      environment: ['clothing', 'background', 'lighting'],
      quality: ['quality', 'style', 'resolution']
    },
    allowedValues: {
      gender: ['male', 'female', 'unknown'],
      faceShape: ['oval', 'round', 'square', 'heart', 'diamond', 'long', 'triangular'],
      eyeShape: ['almond', 'round', 'hooded', 'monolid', 'downturned', 'upturned'],
      noseShape: ['straight', 'aquiline', 'button', 'bulbous', 'pointed', 'broad'],
      lipShape: ['thin', 'full', 'wide', 'narrow', 'heart-shaped'],
      hairColor: ['black', 'brown', 'blonde', 'red', 'gray', 'white', 'bald'],
      quality: ['low', 'standard', 'high'],
      style: ['forensic', 'digital', 'traditional'],
      resolution: ['512x512', '1024x1024', '1792x1024']
    }
  });
});

module.exports = router;