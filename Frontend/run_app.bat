@echo off
echo ==========================================
echo 🚀 Starting Python API Server...
echo ==========================================

:: الأمر ده بيفتح شاشة تيرمينال جديدة لوحدها، بيفعل البيئة الوهمية ويشغل السيرفر
start "FastAPI Server" cmd /k "cd /d E:\document\mobile app\Fit Guard App\Fit Guard\AI\Dashboard-Streamlit-internal-testing\AI-training-khaledk5-patch-1 && D:\Fitness_AI_Project\venv\Scripts\activate && python api.py"

echo ==========================================
echo 📱 Starting Flutter App on Emulator...
echo ==========================================

:: الأمر ده بيشغل فلاتر في التيرمينال الأساسي بتاعك
flutter run