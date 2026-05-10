import os
import time
import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()
router = APIRouter()

# Global rate limit tracker - much longer wait
last_request_time = {"timestamp": 0}
MIN_INTERVAL = 15  # 15 seconds between API calls

# Comprehensive local knowledge base (no API needed)
LOCAL_RESPONSES = {
    # Greetings
    "hi": "👋 Hi! I'm Terra, your farming assistant. Ask me about crops, weather, soil, or yield!",
    "hello": "👋 Hello! Welcome to VigorTerra. I'm Terra, ready to help with farming questions!",
    "hey": "👋 Hey there! What farming question can I help with?",
    
    # Help
    "help": "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
    "what can you do": "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
    "what can you help with": "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
    
    # Crops
    "what crops grow in tunisia": "Tunisia grows: 🌾 Wheat, barley, oats 🫒 Olives 🍇 Grapes 🍅 Tomatoes 🥒 Dates in Sahara",
    "what is wheat": "🌾 Wheat is a cereal grain used for flour, bread, pasta. Grows well in cool climates with moderate rainfall.",
    "what is barley": "🌾 Barley is a cereal grain similar to wheat. Tolerates drier conditions. Used for animal feed and beer.",
    "olive farming": "🫒 Olives need:\n- Mediterranean climate\n- Well-drained soil\n- ~2-3 years before first harvest\n- Prune in late winter",
    "how to grow tomatoes": "🍅 Tomatoes need:\n- Warm temps (60-75°F)\n- Full sunlight (6-8 hours)\n- Rich, well-drained soil\n- Regular watering\n- Support stakes",
    
    # Weather
    "how does rain affect crops": "🌧️ Rain effects:\n✅ Positive: Provides water, reduces irrigation need\n⚠️ Too much: Waterlogging, disease\n⚠️ Too little: Drought stress, low yield",
    "what temperature is best for crops": "Temperature varies by crop:\n- Cool crops (wheat): 50-65°F\n- Warm crops (tomatoes): 65-80°F\n- Hot crops (dates): 75-95°F",
    "how does sun affect plants": "☀️ Sunlight effects:\n- Energy for photosynthesis\n- 6-8 hours minimum for most crops\n- Too much heat: Stress & wilting\n- Too little: Weak growth",
    
    # Soil
    "what is soil ph": "🥔 pH measures soil acidity (1-14 scale):\n- pH 7 = neutral\n- pH < 7 = acidic (good for berries)\n- pH > 7 = alkaline (good for wheat)\n- Most crops: 6-7.5 optimal",
    "how to improve soil": "🥔 Soil improvement:\n✅ Add compost/manure\n✅ Crop rotation\n✅ Mulching\n✅ Avoid over-tilling\n✅ Grow cover crops",
    "what is nitrogen": "🥔 Nitrogen (N):\n- Essential plant nutrient\n- Promotes leaf growth\n- Sources: Manure, legumes, fertilizer\n- Deficiency: Yellow leaves, weak growth",
    "what is phosphorus": "🥔 Phosphorus (P):\n- Root development & flowering\n- Energy production in plants\n- Sources: Bone meal, rock phosphate\n- Deficiency: Poor root growth",
    "what is potassium": "🥔 Potassium (K):\n- Overall plant health\n- Drought resistance\n- Fruit quality\n- Sources: Wood ash, kelp, fertilizer",
    
    # Yield & Predictions
    "how to increase yield": "📊 Increase yield:\n✅ Healthy soil with good nutrients\n✅ Proper irrigation schedule\n✅ Control pests & diseases\n✅ Choose right crop varieties\n✅ Optimal planting density",
    "what affects crop yield": "Factor affecting yield:\n🌧️ Water availability\n☀️ Sunlight\n🌡️ Temperature\n🥔 Soil fertility\n🐛 Pests & diseases\n👨‍🌾 Farming practices",
    "what is yield": "📊 Yield = crop produced per unit area, measured in t/ha (tons per hectare). Affected by soil, weather, practices.",
    "what is t/ha": "📊 t/ha = Tons per Hectare. 1 hectare = 10,000 m². 2.74 t/ha means 2.74 tons from 1 hectare.",
    "what is gradient boosting": "📊 Machine learning model that learns from data patterns. Often very accurate for yield prediction.",
    "what is anomaly": "⚠️ Anomaly = unusual conditions detected. Factors outside normal ranges that can reduce yield.",
    "what is ph": "🥔 pH measures soil acidity (0-14). pH 7 = neutral. Optimal for crops: 6-7.5. Out of range = nutrient problems.",
    "what is humidity": "💧 Moisture in air (0-100%). Low: plant stress. High: disease risk. Optimal: 40-70% for crops.",
    "what is rainfall": "🌧️ Water from rain. Too little: drought. Too much: flooding. Optimal: 400-600mm annual.",
    
    # Irrigation
    "how often to water crops": "💧 Watering depends on:\n- Crop type (1-3 inches/week typical)\n- Soil type (sandy needs more)\n- Weather (less in cool season)\n- Growth stage (more during fruiting)\nCheck soil 2-3 inches deep - water if dry",
    
    # Seasons
    "best time to plant": "📅 Typical planting:\n- Spring (warm crops): March-May\n- Fall (cool crops): August-October\n- Region-dependent (check local climate)",
    
    # Pests & Diseases
    "pest control": "🐛 Pest control:\n✅ Natural: Ladybugs, neem oil\n✅ Chemical: Use sparingly, follow instructions\n✅ Prevention: Crop rotation, healthy soil\n✅ Monitoring: Check plants regularly",
    "how to control pests": "🐛 Pest control:\n✅ Natural: Ladybugs, neem oil\n✅ Chemical: Use sparingly, follow instructions\n✅ Prevention: Crop rotation, healthy soil\n✅ Monitoring: Check plants regularly",
    "what are common pests": "🐛 Common pests:\n- Aphids: Small insects, suck sap\n- Caterpillars: Eat leaves\n- Beetles: Various types damage crops\n- Mites: Tiny spiders, cause yellowing",
    "how to prevent diseases": "🦠 Disease prevention:\n✅ Plant resistant varieties\n✅ Proper spacing for air circulation\n✅ Avoid overhead watering\n✅ Clean tools & equipment\n✅ Crop rotation",
    
    # Fertilizers
    "what fertilizer to use": "🌱 Fertilizer choice:\n- Nitrogen: For leafy growth (urea, ammonium nitrate)\n- Phosphorus: For roots & flowers (superphosphate)\n- Potassium: For fruit quality (potash)\n- Organic: Compost, manure (slower but safer)",
    "organic fertilizer": "🌱 Organic fertilizers:\n✅ Compost: Decomposed plant matter\n✅ Manure: Animal waste (aged)\n✅ Bone meal: For phosphorus\n✅ Fish emulsion: Quick nitrogen boost\n✅ Blood meal: High nitrogen",
    
    # Crop Rotation
    "what is crop rotation": "🌾 Crop rotation:\n- Plant different crops in sequence\n- Prevents soil depletion\n- Reduces pest/disease buildup\n- Improves soil structure\n- Example: Wheat → Legumes → Corn",
    
    # Weather & Climate
    "how to prepare for drought": "🌵 Drought preparation:\n✅ Mulch to retain moisture\n✅ Choose drought-tolerant varieties\n✅ Deep watering less frequently\n✅ Use drip irrigation\n✅ Monitor soil moisture",
    "what to do in flood": "🌊 Flood response:\n✅ Remove standing water quickly\n✅ Check for root rot\n✅ Replant if needed\n✅ Improve drainage\n✅ Use raised beds next time",
    
    # Harvesting
    "when to harvest": "🌾 Harvest timing:\n- Wheat: When grains are hard, straw yellow\n- Tomatoes: When fully colored, slightly soft\n- Olives: When fruit changes color\n- Grapes: When sugar content optimal\nCheck specific crop guides",
    "how to store crops": "📦 Crop storage:\n✅ Cool, dry, dark place\n✅ Good ventilation\n✅ Check for pests regularly\n✅ Use proper containers\n✅ Some crops need curing first",
    
    # Sustainable Farming
    "sustainable farming": "🌱 Sustainable practices:\n✅ Crop rotation\n✅ Organic fertilizers\n✅ Integrated pest management\n✅ Water conservation\n✅ Soil conservation\n✅ Biodiversity promotion",
    "what is organic farming": "🌱 Organic farming:\n- No synthetic pesticides/fertilizers\n- Natural pest control\n- Organic compost/manure\n- Crop rotation\n- Soil health focus\n- Environmentally friendly",
    
    # Tunisia Specific
    "tunisian agriculture": "🇹🇳 Tunisia agriculture:\n- Mediterranean climate\n- Main crops: Wheat, olives, dates\n- Irrigation from dams & groundwater\n- Challenges: Water scarcity, soil erosion\n- Opportunities: Export potential, tourism",
    "best crops for tunisia": "🇹🇳 Best Tunisian crops:\n🌾 Cereals: Wheat, barley (northern regions)\n🫒 Olives: Central & southern\n🍇 Grapes: Coastal areas\n🥭 Dates: Sahara oases\n🍅 Vegetables: Market gardens",
    
    # Equipment & Tools
    "farming tools": "🛠️ Essential tools:\n- Hoe: Weed control\n- Shovel: Digging & planting\n- Rake: Soil leveling\n- Pruners: Plant trimming\n- Irrigation system: Water delivery\n- Tractor: Large operations",
    "irrigation systems": "💧 Irrigation types:\n- Drip: Water-efficient, precise\n- Sprinkler: Even coverage\n- Flood: Simple but wasteful\n- Center pivot: Large fields\nChoose based on crop, soil, water availability",
    
    # Economics
    "farming costs": "💰 Main farming costs:\n- Seeds/seedlings\n- Fertilizers & pesticides\n- Irrigation water\n- Labor\n- Equipment maintenance\n- Land rent/taxes",
    "how to increase profit": "💰 Profit improvement:\n✅ Higher yields through better practices\n✅ Value-added products (processing)\n✅ Direct marketing to consumers\n✅ Crop diversification\n✅ Cost control & efficiency",
    
    # Thanks variations
    "thank you": "😊 You're welcome! Ask anytime!",
    "thanks": "😊 Happy to help! More questions?",
    "bye": "👋 Goodbye! Good luck farming!",
    "goodbye": "👋 Goodbye! Good luck farming!",
    "see you": "👋 See you later! Happy farming!",
}


class AskRequest(BaseModel):
    question: str


class AskResponse(BaseModel):
    answer: str


class ExplainYieldRequest(BaseModel):
    predicted_yield: float
    unit: str = "t/ha"
    model_used: str = "Gradient Boosting"
    yield_quality: str = "Moderate"
    anomaly_detected: bool = False
    anomaly_reasons: list = []


def explain_yield_prediction(req: ExplainYieldRequest) -> str:
    """Explain yield prediction in user-friendly language"""
    result = f"📊 **Yield Prediction Analysis**\n\n"
    
    # Yield value interpretation
    result += f"🎯 **Predicted Yield**: {req.predicted_yield} {req.unit}\n"
    
    if req.predicted_yield < 2:
        result += "⚠️ **Low Yield** - Below optimal production levels\n\n"
    elif req.predicted_yield < 3.5:
        result += "⚠️ **Moderate Yield** - Decent but can improve\n\n"
    else:
        result += "✅ **Good Yield** - Solid production level\n\n"
    
    # Model info
    result += f"📈 **Model Used**: {req.model_used}\n"
    result += f"**Quality**: {req.yield_quality}\n"
    
    if req.yield_quality == "Moderate":
        result += "(Predictions are reasonable, some risk factors present)\n\n"
    elif req.yield_quality == "High":
        result += "(Predictions are very reliable)\n\n"
    elif req.yield_quality == "Low":
        result += "(Predictions have higher uncertainty)\n\n"
    
    # Anomalies explanation
    if req.anomaly_detected:
        result += "⚠️ **Anomalies Detected** (Conditions Outside Normal Ranges):\n"
        
        anomaly_list = []
        if req.anomaly_reasons:
            for reason in req.anomaly_reasons:
                reason_lower = reason.lower()
                if "ph" in reason_lower:
                    anomaly_list.append("🥔 **Soil pH** - Outside agronomic range (optimal: 6-7.5)")
                elif "temperature" in reason_lower:
                    anomaly_list.append("🌡️ **Temperature** - Outside expected range for crop")
                elif "humidity" in reason_lower:
                    anomaly_list.append("💧 **Humidity** - Outside optimal range (ideal: 40-70%)")
                elif "rainfall" in reason_lower:
                    anomaly_list.append("🌧️ **Rainfall** - Outside expected amount")
        
        for item in anomaly_list:
            result += f"- {item}\n"
        
        if anomaly_list:
            result += "\n💡 **How to Fix**:\n"
            result += "✅ Adjust irrigation to match rainfall needs\n"
            result += "✅ Consider soil amendments for pH correction\n"
            result += "✅ Monitor temperature-sensitive growth stages\n"
            result += "✅ Fine-tune watering for humidity control\n"
            result += "✅ Choose crop varieties suited to your climate\n"
    else:
        result += "✅ **No Anomalies** - All conditions are within normal ranges!\nYour farming conditions are well-optimized.\n"
    
    return result


def get_local_response(question: str) -> str | None:
    """Check if question matches local knowledge base"""
    q_lower = question.strip().lower()
    
    # Exact match
    if q_lower in LOCAL_RESPONSES:
        return LOCAL_RESPONSES[q_lower]
    
    # Check for keywords in question
    for key, response in LOCAL_RESPONSES.items():
        if key in q_lower or q_lower in key:
            return response
    
    # Keyword matching for variations
    keywords = {
        "wheat": LOCAL_RESPONSES.get("what is wheat"),
        "barley": LOCAL_RESPONSES.get("what is barley"),
        "olive": LOCAL_RESPONSES.get("olive farming"),
        "tomato": LOCAL_RESPONSES.get("how to grow tomatoes"),
        "rain": LOCAL_RESPONSES.get("how does rain affect crops"),
        "temperature": LOCAL_RESPONSES.get("what temperature is best for crops"),
        "sun": LOCAL_RESPONSES.get("how does sun affect plants"),
        "soil": LOCAL_RESPONSES.get("what is soil ph"),
        "nitrogen": LOCAL_RESPONSES.get("what is nitrogen"),
        "phosphorus": LOCAL_RESPONSES.get("what is phosphorus"),
        "potassium": LOCAL_RESPONSES.get("what is potassium"),
        "yield": LOCAL_RESPONSES.get("how to increase yield"),
        "water": LOCAL_RESPONSES.get("how often to water crops"),
        "plant": LOCAL_RESPONSES.get("best time to plant"),
    }
    
    for word, response in keywords.items():
        if word in q_lower and response:
            return response
    
    return None


@router.post("/ask", response_model=AskResponse)
def ask_agent(request: AskRequest):
    if not request.question or not request.question.strip():
        raise HTTPException(status_code=400, detail="Please ask me something!")

    # Check local knowledge first (instant, no API)
    local_response = get_local_response(request.question)
    if local_response:
        return AskResponse(answer=local_response)

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        raise HTTPException(status_code=401, detail="API key not configured")

    # Strict rate limiting for free tier
    current_time = time.time()
    time_since_last = current_time - last_request_time["timestamp"]
    if time_since_last < MIN_INTERVAL:
        wait_time = int(MIN_INTERVAL - time_since_last) + 1
        raise HTTPException(status_code=429, detail=f"Please wait {wait_time}s before next question")
    
    last_request_time["timestamp"] = current_time

    try:
        import google.generativeai as genai
    except ImportError:
        raise HTTPException(status_code=500, detail="google-generativeai not installed")

    genai.configure(api_key=api_key)
    
    system_prompt = (
        "You are Terra, a helpful agricultural assistant. "
        "Answer farming questions concisely. Keep responses under 100 words."
    )

    try:
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=system_prompt
        )
        response = model.generate_content(request.question, stream=False)
        
        if not response or not response.text:
            raise HTTPException(status_code=500, detail="No response from AI")

        return AskResponse(answer=response.text)

    except Exception as e:
        msg = str(e).lower()
        if "api key" in msg or "unauthorized" in msg:
            raise HTTPException(status_code=401, detail="Invalid API key")
        if "rate" in msg or "quota" in msg or "429" in msg:
            raise HTTPException(status_code=429, detail="API busy. Please try again in 30 seconds.")
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/explain-yield", response_model=AskResponse)
def explain_yield(request: ExplainYieldRequest):
    """Explain yield prediction results in simple language"""
    explanation = explain_yield_prediction(request)
    return AskResponse(answer=explanation)
