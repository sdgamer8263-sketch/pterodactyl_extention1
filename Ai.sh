#!/bin/bash

FILE_PATH="/var/www/pterodactyl/resources/scripts/components/AiChatWidget.tsx"

function build_panel() {
    echo ""
    echo "[*] Building Pterodactyl panel assets (This may take a minute)..."
    cd /var/www/pterodactyl || exit
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production
    php artisan view:clear
    php artisan cache:clear
    chown -R www-data:www-data /var/www/pterodactyl/*
    echo ""
    echo "[✔] Done! Please hard reload (Ctrl+Shift+R) your browser."
    echo ""
    read -p "Press Enter to return to the main menu..."
}

function install_ai() {
    clear
    echo "===================================================="
    echo "       SKA HOST - AI ASSISTANT INSTALLER            "
    echo "===================================================="
    read -p "Enter your AI Assistant Name (Default: VIZION AI): " AI_NAME
    AI_NAME=${AI_NAME:-"VIZION AI"}

    echo ""
    echo "Get Groq API Key: https://console.groq.com/keys"
    read -p "Enter your Groq API Key: " GROQ_KEY

    echo ""
    echo "Get Gemini API Key: https://aistudio.google.com/app/apikey"
    read -p "Enter your Gemini API Key: " GEMINI_KEY

    if [ -z "$GROQ_KEY" ] \vert{}\vert{} [ -z "$GEMINI_KEY" ]; then
        echo "Error: API Keys cannot be empty!"
        sleep 2
        return
    fi

    echo ""
    echo "[*] Configuring AI Assistant by SKA HOST..."
    cd /var/www/pterodactyl || { echo "Pterodactyl not found!"; exit 1; }

# Creating the React Component safely
cat << 'EOF' > $FILE_PATH
import React, { useState, useRef, useEffect } from 'react';
import { ChatAlt2Icon, XIcon, PaperAirplaneIcon, PhotographIcon } from '@heroicons/react/outline';

const GROQ_API_KEY = 'PLACEHOLDER_GROQ_KEY';
const GEMINI_API_KEY = 'PLACEHOLDER_GEMINI_KEY';
const AI_ASSISTANT_NAME = 'PLACEHOLDER_AI_NAME';
const GEMINI_MODEL = 'PLACEHOLDER_GEMINI_MODEL';
const GROQ_MODEL = 'PLACEHOLDER_GROQ_MODEL';

export default () => {
    const [isOpen, setIsOpen] = useState(false);
    const [isExpanded, setIsExpanded] = useState(false);
    const [messages, setMessages] = useState([{ sender: 'ai', text: `Hello! I am ${AI_ASSISTANT_NAME} Assistant. How can I help you today?\n\n💡 Tip: Type "/imagine [anything]" to generate an image!` }]);
    const [input, setInput] = useState('');
    const [image, setImage] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(scrollToBottom, [messages, isOpen, isExpanded]);

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            setImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const sendMessage = async () => {
        if (!input.trim() && !image) return;

        const currentInput = input.trim();
        const newMessages = [...messages, { sender: 'user', text: currentInput, image: imagePreview }];
        setMessages(newMessages as any);
        setInput('');
        setImage(null);
        setImagePreview(null);
        setLoading(true);

        const isImageCommand = currentInput.toLowerCase().startsWith('/imagine') || currentInput.toLowerCase().startsWith('/imagin');
        
        if (isImageCommand) {
            let promptToGenerate = currentInput.replace(/^\/imagin[e]?\s*/i, '').trim();
            if (!promptToGenerate) promptToGenerate = "A beautiful futuristic hosting server";
            
            const randomSeed = Math.floor(Math.random() * 1000000);
            const imageUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(promptToGenerate)}?width=1024&height=1024&nologo=true&seed=${randomSeed}`;
            
            setTimeout(() => {
                setMessages(prev => [...prev, { 
                    sender: 'ai', 
                    text: `Here is the generated image for: "${promptToGenerate}"`, 
                    generatedImage: imageUrl 
                }]);
                setLoading(false);
            }, 1500);
            return;
        }

        try {
            let aiText = "";

            if (imagePreview) {
                let parts: any[] = [{ text: currentInput || "Please describe this image in detail." }];
                const base64Data = imagePreview.split(',')[1];
                parts.push({
                    inlineData: {
                        mimeType: image?.type || 'image/jpeg',
                        data: base64Data
                    }
                });

                const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ contents: [{ parts }] })
                });
                const data = await response.json();
                if (data.error) throw new Error(data.error.message);
                aiText = data.candidates[0].content.parts[0].text;
            } else {
                const response = await fetch(`https://api.groq.com/openai/v1/chat/completions`, {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${GROQ_API_KEY}`
                    },
                    body: JSON.stringify({ 
                        model: GROQ_MODEL,
                        messages: [
                            { role: "system", content: `You are ${AI_ASSISTANT_NAME}, a helpful and fast assistant. You were created and powered by SKA HOST. Provide clear and concise answers.` },
                            { role: "user", content: currentInput }
                        ]
                    })
                });
                const data = await response.json();
                if (data.error) throw new Error(data.error.message);
                aiText = data.choices[0].message.content;
            }

            setMessages(prev => [...prev, { sender: 'ai', text: aiText }]);
        } catch (error: any) {
            setMessages(prev => [...prev, { sender: 'ai', text: `Error: ${error.message}` }]);
        } finally {
            setLoading(false);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    };

    return (
        <div className={`fixed z-[9999] transition-all duration-300 ease-in-out ${isExpanded && isOpen ? 'inset-0 sm:inset-10' : 'bottom-4 right-4 sm:bottom-6 sm:right-6'}`}>
            {!isOpen && (
                <button 
                    onClick={() => setIsOpen(true)}
                    className="w-14 h-14 bg-blue-600 hover:bg-blue-500 text-white rounded-full flex items-center justify-center shadow-lg transition-all duration-300 transform hover:scale-110"
                >
                    <ChatAlt2Icon className="w-7 h-7" />
                </button>
            )}

            {isOpen && (
                <div 
                    className={`bg-gray-800 border border-gray-700 shadow-2xl flex flex-col overflow-hidden transition-all duration-300 ${isExpanded ? 'w-full h-full rounded-none sm:rounded-xl' : 'w-[calc(100vw-2rem)] sm:w-96 rounded-lg'}`} 
                    style={isExpanded ? {} : { height: '550px', maxHeight: '85vh' }}
                >
                    <div className="bg-gray-900 px-4 py-3 flex justify-between items-center border-b border-gray-700 shrink-0">
                        <div className="flex items-center gap-2">
                            <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center font-bold text-white shadow">V</div>
                            <h3 className="font-semibold text-gray-100">{AI_ASSISTANT_NAME}</h3>
                        </div>
                        
                        <div className="flex items-center gap-3">
                            <button 
                                onClick={() => setIsExpanded(!isExpanded)} 
                                className="text-gray-400 hover:text-white transition-colors"
                            >
                                {isExpanded ? (
                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 4v4m0 0H4m4 0L3 3m13 1v4m0 0h4m-4 0l5-5M8 20v-4m0 0H4m4 0l-5 5m13-1v-4m0 0h4m-4 0l5 5"></path></svg>
                                ) : (
                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"></path></svg>
                                )}
                            </button>
                            <button 
                                onClick={() => { setIsOpen(false); setIsExpanded(false); }} 
                                className="text-gray-400 hover:text-red-500 transition-colors"
                            >
                                <XIcon className="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    <div className="flex-1 p-4 overflow-y-auto flex flex-col gap-3 bg-gray-800">
                        {messages.map((msg: any, index) => (
                            <div key={index} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                                <div className={`max-w-[85%] p-3 rounded-lg text-sm ${msg.sender === 'user' ? 'bg-blue-600 text-white rounded-br-none' : 'bg-gray-700 text-gray-200 rounded-bl-none'}`}>
                                    {msg.image && <img src={msg.image} alt="Upload" className="max-w-full rounded mb-2 border border-gray-500" />}
                                    
                                    <div style={{ whiteSpace: 'pre-wrap' }}>{msg.text}</div>
                                    
                                    {msg.generatedImage && (
                                        <div className="mt-3 relative group">
                                            <img src={msg.generatedImage} alt="AI Generated" className="w-full rounded-lg border border-gray-600 shadow-md" />
                                        </div>
                                    )}
                                </div>
                            </div>
                        ))}
                        {loading && (
                            <div className="flex justify-start">
                                <div className="bg-gray-700 text-gray-400 p-3 rounded-lg rounded-bl-none text-sm animate-pulse">
                                    Working on it...
                                </div>
                            </div>
                        )}
                        <div ref={messagesEndRef} />
                    </div>

                    <div className="p-3 bg-gray-900 border-t border-gray-700 flex flex-col gap-2 shrink-0">
                        <div className="flex items-end gap-2">
                            <input type="file" accept="image/*" className="hidden" ref={fileInputRef} onChange={handleImageChange} />
                            <button 
                                onClick={() => fileInputRef.current?.click()}
                                className={`p-2 rounded-full transition-colors ${image ? 'bg-green-600 text-white' : 'bg-gray-700 text-gray-400 hover:text-white hover:bg-gray-600'}`}
                            >
                                <PhotographIcon className="w-5 h-5" />
                            </button>
                            
                            <textarea 
                                value={input}
                                onChange={(e) => setInput(e.target.value)}
                                onKeyDown={handleKeyPress}
                                placeholder="Ask or type /imagine..."
                                className="flex-1 bg-gray-700 text-white rounded-lg px-3 py-2 text-sm resize-none focus:outline-none focus:ring-1 focus:ring-blue-500"
                                rows={isExpanded ? 2 : 1}
                            />
                            
                            <button 
                                onClick={sendMessage}
                                disabled={loading || (!input.trim() && !image)}
                                className="p-2 bg-blue-600 hover:bg-blue-500 disabled:bg-gray-600 text-white rounded-full transition-colors"
                            >
                                <PaperAirplaneIcon className="w-5 h-5 transform rotate-90" />
                            </button>
                        </div>
                        {/* SKA HOST BRANDING CREDIT */}
                        <div className="text-center text-[10px] text-gray-500 mt-1 font-medium tracking-wide">
                            Powered by <span className="text-blue-400">SKA HOST</span>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
EOF

    # Replacing Placeholders
    sed -i "s/PLACEHOLDER_GROQ_KEY/$GROQ_KEY/g" $FILE_PATH
    sed -i "s/PLACEHOLDER_GEMINI_KEY/$GEMINI_KEY/g" $FILE_PATH
    sed -i "s/PLACEHOLDER_AI_NAME/$AI_NAME/g" $FILE_PATH
    sed -i "s/PLACEHOLDER_GEMINI_MODEL/gemini-3.5-flash/g" $FILE_PATH
    sed -i "s/PLACEHOLDER_GROQ_MODEL/llama-3.3-70b-versatile/g" $FILE_PATH

    # Wire widget into routers safely
    grep -q "AiChatWidget" resources/scripts/routers/DashboardRouter.tsx || sed -i 's/import { useTranslation } from '\''react-i18next'\'';/import { useTranslation } from '\''react-i18next'\'';\nimport AiChatWidget from '\''@\/components\/AiChatWidget'\'';/g' resources/scripts/routers/DashboardRouter.tsx
    grep -q "<AiChatWidget />" resources/scripts/routers/DashboardRouter.tsx || sed -i 's/<\/LayoutWrapper>/    <AiChatWidget \/>\n        <\/LayoutWrapper>/g' resources/scripts/routers/DashboardRouter.tsx

    grep -q "AiChatWidget" resources/scripts/routers/ServerRouter.tsx || sed -i 's/import { useFloating } from '\''@\/context\/FloatingContext'\'';/import { useFloating } from '\''@\/context\/FloatingContext'\'';\nimport AiChatWidget from '\''@\/components\/AiChatWidget'\'';/g' resources/scripts/routers/ServerRouter.tsx
    grep -q "<AiChatWidget />" resources/scripts/routers/ServerRouter.tsx || sed -i 's/<\/LayoutWrapper>/    <AiChatWidget \/>\n        <\/LayoutWrapper>/g' resources/scripts/routers/ServerRouter.tsx

    build_panel
}

function change_api_keys() {
    while true; do
        clear
        echo "===================================================="
        echo "               2. CHANGE API KEYS                   "
        echo "===================================================="
        echo "1. Change Groq API Key"
        echo "2. Change Google Gemini API Key"
        echo "3. Back to Main Menu"
        echo "===================================================="
        read -p "Choose an option (1-3): " KEY_OPT

        if [ ! -f "$FILE_PATH" ]; then
            echo "Error: AI Assistant is not installed yet! Please install it first."
            sleep 2
            return
        fi

        case $KEY_OPT in
            1)
                echo ""
                echo "Get Key: https://console.groq.com/keys"
                read -p "Enter new Groq API Key: " NEW_GROQ
                sed -i "s/const GROQ_API_KEY = '.*'/const GROQ_API_KEY = '$NEW_GROQ'/g" $FILE_PATH
                build_panel
                ;;
            2)
                echo ""
                echo "Get Key: https://aistudio.google.com/app/apikey"
                read -p "Enter new Gemini API Key: " NEW_GEMINI
                sed -i "s/const GEMINI_API_KEY = '.*'/const GEMINI_API_KEY = '$NEW_GEMINI'/g" $FILE_PATH
                build_panel
                ;;
            3)
                break
                ;;
            *)
                echo "Invalid Option!"
                sleep 1
                ;;
        esac
    done
}

function change_models() {
    while true; do
        clear
        echo "===================================================="
        echo "             3. CHANGE AI MODEL NAMES               "
        echo "===================================================="
        echo "1. Change Google Gemini Model"
        echo "2. Change Groq Model"
        echo "3. Back to Main Menu"
        echo "===================================================="
        read -p "Choose an option (1-3): " MOD_OPT

        if [ ! -f "$FILE_PATH" ]; then
            echo "Error: AI Assistant is not installed yet! Please install it first."
            sleep 2
            return
        fi

        case $MOD_OPT in
            1)
                echo ""
                echo "Example Models: gemini-3.5-flash, gemini-1.5-pro, etc."
                read -p "Enter new Gemini Model Name: " NEW_G_MODEL
                sed -i "s/const GEMINI_MODEL = '.*'/const GEMINI_MODEL = '$NEW_G_MODEL'/g" $FILE_PATH
                build_panel
                ;;
            2)
                echo ""
                echo "Example Models: llama-3.3-70b-versatile, llama3-8b-8192, etc."
                read -p "Enter new Groq Model Name: " NEW_Q_MODEL
                sed -i "s/const GROQ_MODEL = '.*'/const GROQ_MODEL = '$NEW_Q_MODEL'/g" $FILE_PATH
                build_panel
                ;;
            3)
                break
                ;;
            *)
                echo "Invalid Option!"
                sleep 1
                ;;
        esac
    done
}

# Main Loop
while true; do
    clear
    echo "===================================================="
    echo "          SKA HOST - AI MANAGER & INSTALLER         "
    echo "===================================================="
    echo "1. Install Full AI Assistant"
    echo "2. Change API Keys"
    echo "3. Change AI Model Names"
    echo "4. Exit"
    echo "===================================================="
    read -p "Choose an option (1-4): " MAIN_OPT

    case $MAIN_OPT in
        1) install_ai ;;
        2) change_api_keys ;;
        3) change_models ;;
        4) clear; exit 0 ;;
        *) echo "Invalid option!"; sleep 1 ;;
    esac
done
