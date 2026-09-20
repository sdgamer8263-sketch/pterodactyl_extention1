#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

install_widget() {
    echo -e "${CYAN}=== Installing Vizion AI Widget for Pterodactyl ===${NC}"
    cd /var/www/pterodactyl || { echo -e "${RED}Pterodactyl directory not found!${NC}"; exit 1; }

    echo "[+] Creating necessary directories..."
    mkdir -p resources/scripts/components
    mkdir -p app/Http/Controllers/Admin
    mkdir -p resources/views/admin/ai
    mkdir -p public/assets/extensions/ai

    echo "[+] Writing Admin Controller (AiSettingsController.php)..."
    cat << 'EOF' > app/Http/Controllers/Admin/AiSettingsController.php
<?php
namespace Pterodactyl\Http\Controllers\Admin;
use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Prologue\Alerts\AlertsMessageBag;

class AiSettingsController extends Controller
{
    private $settings;
    private $alert;
    public function __construct(SettingsRepositoryInterface $settings, AlertsMessageBag $alert) {
        $this->settings = $settings;
        $this->alert = $alert;
    }
    public function index(): View {
        return view('admin.ai.index', [
            'ai_name' => $this->settings->get('settings::ai:name', 'VIZION AI'),
            'groq_key' => $this->settings->get('settings::ai:groq_key', ''),
            'gemini_key' => $this->settings->get('settings::ai:gemini_key', ''),
            'openai_key' => $this->settings->get('settings::ai:openai_key', ''),
            'text_provider' => $this->settings->get('settings::ai:text_provider', 'groq'),
            'vision_provider' => $this->settings->get('settings::ai:vision_provider', 'groq'),
            'text_model' => $this->settings->get('settings::ai:text_model', 'llama-3.1-8b-instant'),
            'vision_model' => $this->settings->get('settings::ai:vision_model', 'llama-3.2-11b-vision-preview'),
            'custom_css' => $this->settings->get('settings::ai:custom_css', ''),
            'bg_url' => $this->settings->get('settings::ai:bg_url', ''),
            'logo_url' => $this->settings->get('settings::ai:logo_url', ''),
            'ui_theme' => $this->settings->get('settings::ai:ui_theme', 'cyberpunk'),
        ]);
    }
    public function update(Request $request): RedirectResponse {
        $this->settings->set('settings::ai:name', $request->input('ai_name', 'VIZION AI'));
        $this->settings->set('settings::ai:groq_key', $request->input('groq_key', ''));
        $this->settings->set('settings::ai:gemini_key', $request->input('gemini_key', ''));
        $this->settings->set('settings::ai:openai_key', $request->input('openai_key', ''));
        $this->settings->set('settings::ai:text_provider', $request->input('text_provider', 'groq'));
        $this->settings->set('settings::ai:vision_provider', $request->input('vision_provider', 'groq'));
        $this->settings->set('settings::ai:text_model', $request->input('text_model', 'llama-3.1-8b-instant'));
        $this->settings->set('settings::ai:vision_model', $request->input('vision_model', 'llama-3.2-11b-vision-preview'));
        $this->settings->set('settings::ai:custom_css', $request->input('custom_css', ''));
        $this->settings->set('settings::ai:ui_theme', $request->input('ui_theme', 'cyberpunk'));

        $bgUrl = $request->input('bg_url', '');
        if ($request->hasFile('bg_file')) {
            $file = $request->file('bg_file');
            $filename = 'ai_bg_' . time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('assets/extensions/ai'), $filename);
            $bgUrl = '/assets/extensions/ai/' . $filename;
        }
        $this->settings->set('settings::ai:bg_url', $bgUrl);

        $logoUrl = $request->input('logo_url', '');
        if ($request->hasFile('logo_file')) {
            $file = $request->file('logo_file');
            $filename = 'ai_logo_' . time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('assets/extensions/ai'), $filename);
            $logoUrl = '/assets/extensions/ai/' . $filename;
        }
        $this->settings->set('settings::ai:logo_url', $logoUrl);

        $this->alert->success('AI settings and Custom CSS updated successfully!')->flash();
        return redirect()->route('admin.ai');
    }
}
EOF

    echo "[+] Writing Admin Blade View (index.blade.php)..."
    cat << 'EOF' > resources/views/admin/ai/index.blade.php
@extends('layouts.admin')
@section('title') AI Settings & Customization @endsection
@section('content-header')
    <h1>AI Customization Panel<small>Text, Vision & App Styling</small></h1>
    <ol class="breadcrumb"><li><a href="{{ route('admin.index') }}">Admin</a></li><li class="active">AI Settings</li></ol>
@endsection
@section('content')
<div class="row">
    <div class="col-xs-12">
        <form method="POST" action="{{ route('admin.ai.update') }}" enctype="multipart/form-data">
            @csrf
            <div class="box box-primary">
                <div class="box-header with-border"><h3 class="box-title"><i class="fa fa-key"></i> 1. API Keys & Models</h3></div>
                <div class="box-body row">
                    <div class="form-group col-md-3">
                        <label>AI Assistant Name</label>
                        <input type="text" name="ai_name" value="{{ $ai_name }}" class="form-control" required />
                    </div>
                    <div class="form-group col-md-3">
                        <label>Groq API Key</label>
                        <input type="password" id="groq_key" name="groq_key" value="{{ $groq_key }}" class="form-control" placeholder="gsk_..." />
                    </div>
                    <div class="form-group col-md-3">
                        <label>Google Gemini API Key</label>
                        <input type="password" id="gemini_key" name="gemini_key" value="{{ $gemini_key }}" class="form-control" placeholder="AIza..." />
                    </div>
                    <div class="form-group col-md-3">
                        <label>OpenAI API Key</label>
                        <input type="password" id="openai_key" name="openai_key" value="{{ $openai_key }}" class="form-control" placeholder="sk-..." />
                    </div>
                </div>

                <div class="box-body row" style="border-top: 1px solid #f4f4f4;">
                    <div class="col-md-6" style="border-right: 1px solid #f4f4f4;">
                        <h4>📝 Text Provider & Model</h4>
                        <div class="form-group">
                            <label class="radio-inline"><input type="radio" name="text_provider" value="groq" {{ $text_provider === 'groq' ? 'checked' : '' }}> Groq</label>
                            <label class="radio-inline"><input type="radio" name="text_provider" value="gemini" {{ $text_provider === 'gemini' ? 'checked' : '' }}> Gemini</label>
                            <label class="radio-inline"><input type="radio" name="text_provider" value="openai" {{ $text_provider === 'openai' ? 'checked' : '' }}> OpenAI</label>
                        </div>
                        <div class="input-group">
                            <input type="text" id="text_model_input" name="text_model" value="{{ $text_model }}" class="form-control" />
                            <select id="text_model_select" class="form-control" style="display:none;"></select>
                            <span class="input-group-btn"><button type="button" class="btn btn-info" onclick="fetchModels('text')">Load</button></span>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <h4>👁️ Vision Provider & Model</h4>
                        <div class="form-group">
                            <label class="radio-inline"><input type="radio" name="vision_provider" value="groq" {{ $vision_provider === 'groq' ? 'checked' : '' }}> Groq</label>
                            <label class="radio-inline"><input type="radio" name="vision_provider" value="gemini" {{ $vision_provider === 'gemini' ? 'checked' : '' }}> Gemini</label>
                            <label class="radio-inline"><input type="radio" name="vision_provider" value="openai" {{ $vision_provider === 'openai' ? 'checked' : '' }}> OpenAI</label>
                        </div>
                        <div class="input-group">
                            <input type="text" id="vision_model_input" name="vision_model" value="{{ $vision_model }}" class="form-control" />
                            <select id="vision_model_select" class="form-control" style="display:none;"></select>
                            <span class="input-group-btn"><button type="button" class="btn btn-info" onclick="fetchModels('vision')">Load</button></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="box box-success">
                <div class="box-header with-border"><h3 class="box-title"><i class="fa fa-paint-brush"></i> 2. Branding, UI Customization & Custom CSS</h3></div>
                <div class="box-body row">
                    <div class="form-group col-md-4">
                        <label>UI Theme Style</label>
                        <select name="ui_theme" class="form-control">
                            <option value="cyberpunk" {{ $ui_theme === 'cyberpunk' ? 'selected' : '' }}>Cyberpunk Dark</option>
                            <option value="neon" {{ $ui_theme === 'neon' ? 'selected' : '' }}>Neon Emerald</option>
                            <option value="royal" {{ $ui_theme === 'royal' ? 'selected' : '' }}>Royal Purple</option>
                            <option value="minimal" {{ $ui_theme === 'minimal' ? 'selected' : '' }}>Clean Minimalist</option>
                        </select>
                    </div>
                    <div class="form-group col-md-4">
                        <label>Logo Image URL (AI Avatar)</label>
                        <input type="text" name="logo_url" value="{{ $logo_url }}" class="form-control" placeholder="https://..." />
                    </div>
                    <div class="form-group col-md-4">
                        <label>Or Upload Logo</label>
                        <input type="file" name="logo_file" class="form-control" accept="image/*" />
                    </div>
                </div>
                <div class="box-body row" style="border-top: 1px solid #f4f4f4;">
                    <div class="form-group col-md-6">
                        <label>Background Image URL</label>
                        <input type="text" name="bg_url" value="{{ $bg_url }}" class="form-control" />
                    </div>
                    <div class="form-group col-md-6">
                        <label>Or Upload Background</label>
                        <input type="file" name="bg_file" class="form-control" accept="image/*" />
                    </div>
                    <div class="form-group col-md-12">
                        <label>Custom CSS (Override Widget Styles)</label>
                        <textarea name="custom_css" class="form-control" rows="4" placeholder="/* Enter your custom CSS here */">{{ $custom_css }}</textarea>
                    </div>
                </div>
                <div class="box-footer">
                    <button type="submit" class="btn btn-success pull-right"><i class="fa fa-save"></i> Save Settings</button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
async function fetchModels(type) {
    let provider = document.querySelector(`input[name="${type}_provider"]:checked`).value;
    let key = document.getElementById(`${provider}_key`).value;
    let inputEl = document.getElementById(`${type}_model_input`);
    let selectEl = document.getElementById(`${type}_model_select`);
    if(!key) { alert(`Please enter your ${provider.toUpperCase()} API Key first!`); return; }
    inputEl.style.display = 'none'; selectEl.style.display = 'inline-block'; selectEl.innerHTML = '<option>Loading...</option>';
    try {
        let models = [];
        if (provider === 'groq' || provider === 'openai') {
            let url = provider === 'groq' ? 'https://api.groq.com/openai/v1/models' : 'https://api.openai.com/v1/models';
            let res = await fetch(url, { headers: { 'Authorization': 'Bearer ' + key } });
            let data = await res.json();
            models = data.data.map(m => m.id).filter(id => !id.includes('whisper') && !id.includes('guard'));
        } else if (provider === 'gemini') {
            let res = await fetch('https://generativelanguage.googleapis.com/v1beta/models?key=' + key);
            let data = await res.json();
            models = data.models.map(m => m.name.replace('models/', ''));
        }
        selectEl.innerHTML = '';
        models.forEach(m => {
            let opt = document.createElement('option'); opt.value = m; opt.text = m;
            if(m === inputEl.value) opt.selected = true; selectEl.appendChild(opt);
        });
        inputEl.value = selectEl.value; selectEl.onchange = () => { inputEl.value = selectEl.value; };
    } catch (e) { alert('Failed to load models.'); selectEl.style.display = 'none'; inputEl.style.display = 'inline-block'; }
}
</script>
@endsection
EOF

    echo "[+] Updating Pterodactyl Wrapper config injector..."
    cat << 'PHP_INJECT' > inject_config.php
<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);$kernel->bootstrap();

$path = "/var/www/pterodactyl/resources/views/templates/wrapper.blade.php";
$content = file_get_contents($path);
$content = preg_replace("/<script>window\.AI_CONFIG.*?<\/script>\n?/", "", $content);

$inject = "<script>window.AI_CONFIG = { name: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:name', 'VIZION AI') }}\", logo_url: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:logo_url', '') }}\", groq_key: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:groq_key', '') }}\", gemini_key: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:gemini_key', '') }}\", openai_key: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:openai_key', '') }}\", text_provider: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:text_provider', 'groq') }}\", vision_provider: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:vision_provider', 'groq') }}\", text_model: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:text_model', 'llama-3.1-8b-instant') }}\", vision_model: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:vision_model', 'llama-3.2-11b-vision-preview') }}\", custom_css: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:custom_css', '') }}\", bg_url: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:bg_url', '') }}\", ui_theme: \"{{ app('Pterodactyl\\\\Contracts\\\\Repository\\\\SettingsRepositoryInterface')->get('settings::ai:ui_theme', 'cyberpunk') }}\" };</script>\n";

$content = str_replace("</head>", $inject . "</head>", $content);
file_put_contents($path,$content);
PHP_INJECT
    php inject_config.php
    rm -f inject_config.php

    echo "[+] Writing Premium React Widget (AiChatWidget.tsx)..."
    cat << 'EOF' > resources/scripts/components/AiChatWidget.tsx
import React, { useState, useRef, useEffect } from 'react';
import { ChatAlt2Icon, XIcon, PaperAirplaneIcon, PhotographIcon, MinusIcon, ViewBoardsIcon } from '@heroicons/react/outline';

type ChatMode = 'good' | 'pro' | 'hacker';
type MediaMode = 'text' | 'image';

export default () => {
    const aiConfig = (window as any).AI_CONFIG || {};
    const [isOpen, setIsOpen] = useState(false);
    const [isMinimized, setIsMinimized] = useState(false);
    const [isExpanded, setIsExpanded] = useState(false);
    
    const [chatMode, setChatMode] = useState<ChatMode>('good');
    const [mediaMode, setMediaMode] = useState<MediaMode>('text');
    const [animeStyle, setAnimeStyle] = useState(false);

    const [messages, setMessages] = useState<any[]>([{ sender: 'ai', text: `Welcome to ${aiConfig.name || 'AI'} ✦\nPowered by SKA HOST.` }]);
    const [input, setInput] = useState('');
    const [image, setImage] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => { messagesEndRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages, isOpen, isExpanded, isMinimized]);

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            setImage(file);
            const reader = new FileReader();
            reader.onloadend = () => setImagePreview(reader.result as string);
            reader.readAsDataURL(file);
        }
    };

    const sendMessage = async () => {
        if (!input.trim() && !image) return;
        const currentInput = input.trim();
        setMessages(prev => [...prev, { sender: 'user', text: currentInput, image: imagePreview }]);
        setInput(''); setImage(null); setImagePreview(null); setLoading(true);

        try {
            let finalImgUrl: string | undefined = undefined;
            let promptClean = currentInput.replace(/^\/imagin[e]?\s*/i, '').replace(/generate/gi, '').trim() || "Real world photo";
            
            if (animeStyle) {
                promptClean += ", anime style, masterclass 2D illustration, vibrant colors, studio ghibli aesthetic";
            } else if (chatMode === 'hacker') {
                promptClean += ", raw unedited street photography, real world documentary photo, natural gritty lighting, authentic everyday life snapshot, less polish, brutal realism";
            } else if (chatMode === 'pro') {
                promptClean += ", professional architectural rendering, studio cinematic lighting, 8k resolution, hyper-realistic";
            } else {
                promptClean += ", natural candid photography, everyday real life lighting, clear details";
            }

            const uniqueSeed = Math.floor(Math.random() * 999999999);

            if (mediaMode === 'image') {
                finalImgUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(promptClean)}?width=1024&height=1024&nologo=true&private=true&model=flux&seed=${uniqueSeed}`;
                setTimeout(() => { 
                    setMessages(prev => [...prev, { sender: 'ai', text: `✨ Generated Image (${chatMode.toUpperCase()} Mode${animeStyle ? ' + Anime' : ''}):`, generatedImage: finalImgUrl }]); 
                    setLoading(false); 
                }, 500);
                return;
            }

            let sysPrompt = `You are ${aiConfig.name}, an advanced AI by SKA HOST.`;
            if (chatMode === 'hacker') sysPrompt += " Elite cybersecurity expert. Raw, optimized, practical code.";
            if (chatMode === 'pro') sysPrompt += " Senior Software Architect & Mathematician.";

            let provider = imagePreview ? (aiConfig.vision_provider || 'groq') : (aiConfig.text_provider || 'groq');
            let model = imagePreview ? (aiConfig.vision_model || 'llama-3.2-11b-vision-preview') : (aiConfig.text_model || 'llama-3.1-8b-instant');
            let key = provider === 'groq' ? aiConfig.groq_key : provider === 'openai' ? aiConfig.openai_key : aiConfig.gemini_key;
            
            if (!key) throw new Error(`${provider.toUpperCase()} API Key is missing. Check Admin Settings.`);

            let aiResponseText = "";
            if (provider === 'groq' || provider === 'openai') {
                let url = provider === 'groq' ? 'https://api.groq.com/openai/v1/chat/completions' : 'https://api.openai.com/v1/chat/completions';
                let res = await fetch(url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` },
                    body: JSON.stringify({
                        model: model,
                        messages: [
                            { role: "system", content: sysPrompt },
                            { role: "user", content: imagePreview ? [{ type: "text", text: currentInput || "Analyze image." }, { type: "image_url", image_url: { url: imagePreview } }] : currentInput }
                        ]
                    })
                });
                let data = await res.json();
                if (data.error) throw new Error(data.error.message);
                aiResponseText = data.choices[0].message.content;
            } else if (provider === 'gemini') {
                let cleanModel = model.replace('models/', '');
                let url = `https://generativelanguage.googleapis.com/v1beta/models/${cleanModel}:generateContent?key=${key}`;
                let parts: any[] = [{ text: currentInput || "Describe this." }];
                if (imagePreview) {
                    const mimeType = imagePreview.split(';')[0].split(':')[1];
                    const base64Data = imagePreview.split(',')[1];
                    parts.push({ inlineData: { mimeType: mimeType, data: base64Data } });
                }
                let res = await fetch(url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ systemInstruction: { parts: [{ text: sysPrompt }] }, contents: [{ parts: parts }] })
                });
                let data = await res.json();
                if (data.error) throw new Error(data.error.message);
                aiResponseText = data.candidates[0].content.parts[0].text;
            }

            setMessages(prev => [...prev, { sender: 'ai', text: aiResponseText }]);
        } catch (err: any) { setMessages(prev => [...prev, { sender: 'ai', text: `Error: ${err.message}` }]); } finally { setLoading(false); }
    };

    const getThemeStyles = () => {
        switch(aiConfig.ui_theme) {
            case 'neon': return { primary: 'from-emerald-500 via-green-600 to-teal-700', shadow: 'shadow-[0_0_25px_rgba(16,185,129,0.4)]', text: 'text-emerald-400', border: 'border-emerald-500/30' };
            case 'royal': return { primary: 'from-purple-600 via-indigo-600 to-violet-800', shadow: 'shadow-[0_0_25px_rgba(147,51,234,0.4)]', text: 'text-purple-400', border: 'border-purple-500/30' };
            case 'minimal': return { primary: 'from-slate-700 via-zinc-800 to-gray-900', shadow: 'shadow-[0_0_25px_rgba(100,116,139,0.4)]', text: 'text-gray-300', border: 'border-gray-500/30' };
            default: return { primary: 'from-cyan-500 via-blue-600 to-indigo-700', shadow: 'shadow-[0_0_25px_rgba(6,182,212,0.4)]', text: 'text-cyan-400', border: 'border-cyan-500/30' };
        }
    };
    const theme = getThemeStyles();

    return (
        <div className={`z-[99999] font-sans select-none ${isExpanded ? 'fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center p-2 sm:p-6' : 'fixed bottom-6 right-6 flex flex-col items-end'}`}>
            <style dangerouslySetInnerHTML={{__html: `
                ${aiConfig.custom_css || ''}
                .ai-bg-custom { ${aiConfig.bg_url ? `background-image: url('${aiConfig.bg_url}'); background-size: cover; background-position: center;` : ''} }
            `}} />

            {!isOpen && (
                <button onClick={() => { setIsOpen(true); setIsMinimized(false); }} className={`group relative w-16 h-16 rounded-2xl bg-gradient-to-tr ${theme.primary} p-0.5 ${theme.shadow} hover:scale-105 transition-all duration-300`}>
                    <div className="w-full h-full bg-[#080d1a]/90 backdrop-blur-xl rounded-2xl flex items-center justify-center overflow-hidden">
                        {aiConfig.logo_url ? (
                            <img src={aiConfig.logo_url} alt="Logo" className="w-full h-full object-cover rounded-2xl" />
                        ) : (
                            <ChatAlt2Icon className={`w-8 h-8 ${theme.text} group-hover:text-white transition-colors`} />
                        )}
                    </div>
                </button>
            )}

            {isOpen && (
                <div className={`relative bg-[#070b14]/95 ai-bg-custom backdrop-blur-3xl border border-white/10 ${theme.shadow} flex flex-col overflow-hidden transition-all duration-300 ${isExpanded ? 'w-full h-full sm:w-[90vw] sm:h-[90vh] rounded-none sm:rounded-3xl' : isMinimized ? 'w-[calc(100vw-2rem)] sm:w-[420px] h-16 rounded-2xl' : 'w-[calc(100vw-2rem)] sm:w-[420px] h-[640px] max-h-[85vh] rounded-3xl'}`}>
                    
                    {/* Header */}
                    <div className="px-5 py-4 flex justify-between items-center border-b border-white/10 bg-white/[0.04] backdrop-blur-xl shrink-0">
                        <div className="flex items-center gap-3">
                            {aiConfig.logo_url ? (
                                <img src={aiConfig.logo_url} alt="Logo" className="w-10 h-10 rounded-2xl shadow-lg border border-white/20 object-cover bg-white/5" />
                            ) : (
                                <div className={`w-10 h-10 rounded-2xl bg-gradient-to-tr ${theme.primary} flex items-center justify-center shadow-lg border border-white/20`}><span className="font-extrabold text-white tracking-wider">V</span></div>
                            )}
                            <div>
                                <h3 className="font-bold text-gray-100 flex items-center gap-2">{aiConfig.name || 'AI'} <span className={`text-[10px] bg-black/50 ${theme.text} px-2.5 py-0.5 rounded-full border ${theme.border} font-semibold shadow-inner`}>PRO</span></h3>
                                <div className="flex items-center gap-1.5 mt-0.5"><span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span><span className="text-[11px] text-gray-400 font-medium">SKA HOST</span></div>
                            </div>
                        </div>
                        <div className="flex items-center gap-1.5">
                            <button onClick={() => setIsMinimized(!isMinimized)} className="p-2 text-gray-400 hover:text-white hover:bg-white/10 rounded-xl transition-all" title="Minimize"><MinusIcon className="w-4 h-4" /></button>
                            <button onClick={() => { setIsExpanded(!isExpanded); setIsMinimized(false); }} className="p-2 text-gray-400 hover:text-white hover:bg-white/10 rounded-xl transition-all" title="Fullscreen"><ViewBoardsIcon className="w-4 h-4" /></button>
                            <button onClick={() => { setIsOpen(false); setIsExpanded(false); setIsMinimized(false); }} className="p-2 text-gray-400 hover:text-red-400 hover:bg-red-400/10 rounded-xl transition-all" title="Close"><XIcon className="w-5 h-5" /></button>
                        </div>
                    </div>

                    {!isMinimized && (
                        <>
                            {/* Premium Sleek Mode Selectors */}
                            <div className="bg-white/[0.02] px-4 py-3 flex flex-col gap-2.5 shrink-0 border-b border-white/10 backdrop-blur-md">
                                <div className="flex bg-black/60 rounded-2xl p-1.5 gap-1.5 border border-white/10 shadow-inner">
                                    {(['good', 'pro', 'hacker'] as ChatMode[]).map(m => (
                                        <button key={m} onClick={() => setChatMode(m)} className={`flex-1 text-[11px] uppercase py-2 rounded-xl font-extrabold tracking-wider transition-all duration-300 shadow-sm ${chatMode === m ? `bg-gradient-to-r ${theme.primary} text-white shadow-[0_0_15px_rgba(255,255,255,0.2)] scale-[1.02]` : 'text-gray-400 hover:text-white hover:bg-white/5'}`}>{m}</button>
                                    ))}
                                </div>
                                <div className="flex bg-black/60 rounded-2xl p-1.5 gap-1.5 border border-white/10 shadow-inner">
                                    {(['text', 'image'] as MediaMode[]).map(m => (
                                        <button key={m} onClick={() => setMediaMode(m)} className={`flex-1 text-[11px] uppercase py-2 rounded-xl font-extrabold tracking-wider transition-all duration-300 shadow-sm ${mediaMode === m ? 'bg-gradient-to-r from-purple-600 via-pink-600 to-rose-600 text-white shadow-[0_0_15px_rgba(236,72,153,0.3)] scale-[1.02]' : 'text-gray-400 hover:text-white hover:bg-white/5'}`}>{m}</button>
                                    ))}
                                </div>
                                <div className="flex items-center justify-between px-1.5 pt-1">
                                    <label className="text-xs text-gray-300 flex items-center gap-2 cursor-pointer font-medium hover:text-white transition-colors">
                                        <input type="checkbox" checked={animeStyle} onChange={e => setAnimeStyle(e.target.checked)} className="rounded bg-black/60 border-white/20 text-purple-600 focus:ring-0 w-4 h-4 cursor-pointer" />
                                        🌸 Anime Style Mode
                                    </label>
                                    <span className="text-[10px] text-cyan-400 font-bold uppercase tracking-wider bg-cyan-500/10 px-2 py-0.5 rounded-md border border-cyan-500/20">{mediaMode} Active</span>
                                </div>
                            </div>

                            {/* Chat Messages Body */}
                            <div className="flex-1 p-4 overflow-y-auto flex flex-col gap-4 custom-scrollbar">
                                {messages.map((msg, idx) => (
                                    <div key={idx} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                                        <div className={`max-w-[85%] p-4 text-sm shadow-xl ${msg.sender === 'user' ? 'bg-gradient-to-br from-blue-600 to-indigo-700 text-white rounded-2xl rounded-tr-sm border border-blue-400/20' : 'bg-white/10 text-gray-100 rounded-2xl rounded-tl-sm backdrop-blur-2xl border border-white/10'}`}>
                                            {msg.image && <img src={msg.image} className="max-w-full rounded-xl mb-2 border border-white/20 shadow-md" />}
                                            <div style={{ whiteSpace: 'pre-wrap' }} className="leading-relaxed">{msg.text}</div>
                                            {msg.generatedImage && (
                                                <div className="mt-3.5 bg-black/60 rounded-2xl border border-white/15 p-2.5 flex flex-col items-center shadow-2xl backdrop-blur-xl">
                                                    <img 
                                                        src={msg.generatedImage} 
                                                        alt="AI Art" 
                                                        className="w-full h-auto rounded-xl shadow-lg object-cover border border-white/10" 
                                                        loading="eager"
                                                        crossOrigin="anonymous"
                                                    />
                                                    <a href={msg.generatedImage} target="_blank" rel="noreferrer" className="mt-3 text-xs bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white px-4 py-1.5 rounded-xl font-bold transition-all shadow-lg border border-cyan-400/30">Open Full Image ↗</a>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                                {loading && <div className="flex justify-start"><div className="bg-white/10 px-4 py-3 rounded-2xl rounded-tl-sm flex gap-2 border border-white/10 backdrop-blur-xl"><div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce"></div><div className="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div><div className="w-2 h-2 bg-pink-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }}></div></div></div>}
                                <div ref={messagesEndRef} />
                            </div>

                            {/* Input Footer */}
                            <div className="p-3.5 bg-white/[0.03] border-t border-white/10 shrink-0 backdrop-blur-2xl">
                                <div className="flex items-end gap-2.5">
                                    <input type="file" accept="image/*" className="hidden" ref={fileInputRef} onChange={handleImageChange} />
                                    <button onClick={() => fileInputRef.current?.click()} className={`p-3 rounded-2xl border transition-all ${image ? 'bg-emerald-500/25 text-emerald-400 border-emerald-500/60 shadow-[0_0_15px_rgba(16,185,129,0.3)]' : 'bg-black/50 text-gray-400 hover:text-white border-white/10 hover:bg-white/5'}`} title="Upload Image"><PhotographIcon className="w-5 h-5" /></button>
                                    <textarea value={input} onChange={(e) => setInput(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } }} placeholder={mediaMode === 'image' ? "Describe image to generate..." : "Message Vizion AI..."} className="flex-1 bg-black/50 border border-white/10 rounded-2xl px-4 py-3 text-sm text-white resize-none outline-none focus:border-cyan-500/60 focus:ring-1 focus:ring-cyan-500/40 shadow-inner" rows={isExpanded ? 3 : 1} />
                                    <button onClick={sendMessage} disabled={loading || (!input.trim() && !image)} className={`p-3 bg-gradient-to-tr ${theme.primary} disabled:opacity-40 text-white rounded-2xl shadow-lg transition-transform active:scale-95`}><PaperAirplaneIcon className="w-5 h-5 transform rotate-90" /></button>
                                </div>
                            </div>
                        </>
                    )}
                </div>
            )}
            <style dangerouslySetInnerHTML={{__html: `.custom-scrollbar::-webkit-scrollbar { width: 4px; } .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 4px; }`}} />
        </div>
    );
};
EOF

    echo "[+] Building panel assets (This may take a few minutes)..."
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production

    echo "[+] Clearing Laravel caches..."
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    chown -R www-data:www-data /var/www/pterodactyl/*

    echo -e "${GREEN}[✔] Vizion AI Widget successfully installed!${NC}"
}

uninstall_widget() {
    echo -e "${RED}=== Uninstalling Vizion AI Widget ===${NC}"
    cd /var/www/pterodactyl || { echo -e "${RED}Pterodactyl directory not found!${NC}"; exit 1; }

    echo "[+] Disabling Frontend Widget..."
    cat << 'EOF' > resources/scripts/components/AiChatWidget.tsx
import React from 'react';
export default () => null;
EOF

    echo "[+] Restoring basic Admin Controller to prevent 500 errors..."
    cat << 'EOF' > app/Http/Controllers/Admin/AiSettingsController.php
<?php
namespace Pterodactyl\Http\Controllers\Admin;
use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Http\Controllers\Controller;

class AiSettingsController extends Controller
{
    public function index(): View {
        return view('admin.ai.index');
    }
    public function update(Request $request): RedirectResponse {
        return redirect()->route('admin.ai');
    }
}
EOF
    
    mkdir -p resources/views/admin/ai
    cat << 'EOF' > resources/views/admin/ai/index.blade.php
@extends('layouts.admin')
@section('title') AI Settings @endsection
@section('content-header')
    <h1>AI Settings<small>Status</small></h1>
    <ol class="breadcrumb"><li><a href="{{ route('admin.index') }}">Admin</a></li><li class="active">AI Settings</li></ol>
@endsection
@section('content')
<div class="row">
    <div class="col-xs-12">
        <div class="alert alert-danger">
            <h4><i class="icon fa fa-ban"></i> Uninstalled!</h4>
            The Vizion AI Widget has been successfully uninstalled and disabled. You can safely reinstall it anytime using the setup script.
        </div>
    </div>
</div>
@endsection
EOF

    echo "[+] Removing Wrapper config injection..."
    cat << 'PHP_REMOVE' > remove_config.php
<?php
$path = "/var/www/pterodactyl/resources/views/templates/wrapper.blade.php";
if(file_exists($path)) {
    $content = file_get_contents($path);
    $content = preg_replace("/<script>window\.AI_CONFIG.*?<\/script>\n?/", "", $content);
    file_put_contents($path,$content);
}
PHP_REMOVE
    php remove_config.php
    rm -f remove_config.php

    echo "[+] Rebuilding frontend assets (Removing widget from dashboard)..."
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production

    echo "[+] Clearing caches..."
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    chown -R www-data:www-data /var/www/pterodactyl/*

    echo -e "${GREEN}[✔] Vizion AI Widget successfully disabled & uninstalled!${NC}"
}

while true; do
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${GREEN}    VIZION AI WIDGET - GITHUB MANAGER${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo " 1) Install / Update AI Widget"
    echo " 2) Uninstall AI Widget"
    echo " 3) Exit"
    echo -e "${CYAN}==========================================${NC}"
    read -p "Select an option [1-3]: " choice

    case $choice in
        1)
            install_widget
            read -p "Press Enter to return to menu..."
            ;;
        2)
            uninstall_widget
            read -p "Press Enter to return to menu..."
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Please try again.${NC}"
            sleep 2
            ;;
    esac
done
