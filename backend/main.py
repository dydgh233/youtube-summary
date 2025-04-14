import re
import logging
from fastapi import FastAPI, Request
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
from youtube_transcript_api import YouTubeTranscriptApi
from dotenv import load_dotenv
from fastapi.responses import JSONResponse

load_dotenv()

app = FastAPI()

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class YoutubeRequest(BaseModel):
    videoUrl: str

def extract_video_id(url: str) -> str:
    import re
    match = re.search(r"(?:v=|youtu\.be/)([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None

@app.post("/summarize-youtube")
async def summarize_youtube(req: YoutubeRequest):
    try:
        video_id = extract_video_id(req.videoUrl)
        language_cd = req.languageCode
        if not video_id:
            return {"error": "유효한 YouTube URL이 아닙니다."}

        transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=["ko"])
        text = " ".join([entry["text"] for entry in transcript])

        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
                    "HTTP-Referer": "http://localhost:8000",
                    "X-Title": "youtube-summarizer"
                },
                json={
                    "model": "deepseek/deepseek-r1:free",
                    "messages": [{
                        "role": "user",
                        "content": f"""다음은 유튜브 영상 자막입니다. 이 자막을 {language_cd} 플러터 Markdown 형식으로 활용 하게 요약해주세요.
                        - html 형식으로 요약해주세요.
                        - 핵심 내용이나 강조할 키워드는 <Strong> 을 입혀줘.
                        - 꼭 10문장 이내로 부탁하고, 핵심이 명확하면 됩니다.
                        - 정보의 흐름에 따라 **소제목과 항목을 구분**해주세요.
                        - 중복 표현은 제거하고, 문장은 간결하고 명확하게 작성해주세요.
                        자막:
                        {text}
                        """
                    }]
                }
            )

        # 응답 확인을 위한 출력
        if response.status_code != 200:
            return {"error": f"OpenRouter 오류: {response.status_code}"}

        data = response.json()
        logger.info(f"Response Data: {data}")  # 응답 데이터 확인
        summary = data.get('choices', [{}])[0].get('message', {}).get('content', '')
        
        def clean_html_summary(html_string):
            # HTML 태그와 백틱을 제거하는 정규식
            clean_text = re.sub(r'```html|```', '', html_string)  # 백틱과 HTML 태그 제거
            return clean_text

        summary = clean_html_summary(summary)  # summary를 정리합니다.
        logger.info(f"Summary: {summary}")  # 요약 확인

        if not summary:
            logger.error("DeepSeek API에서 요약을 받지 못했습니다.")
            return {"error": "DeepSeek API에서 요약을 받지 못했습니다."}

        return JSONResponse(content={"summary": summary})

    except Exception as e:
        logger.error(f"Error: {e}")
        return {
            "error": "자막이 없는 영상입니다" if "Transcript disabled" in str(e)
            else "서버 내부 오류가 발생했습니다."
        }
