#!/bin/bash
set -e 

# ==========================================
# ADVANCED PTERODACTYL THEME & ADDON INSTALLER
# ========================================== 

API_URL="http://78.154.103.27:13915/api/verify" 
ADDON_URL="https://github.com/nobita329/Nobita-Cloud/raw/refs/heads/main/thame/Extension"

# --- Colors & Typography ---
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color 

# --- Custom Loggers ---
info() { echo -e "${BLUE}[ℹ] ${WHITE}$1${NC}"; }
success() { echo -e "${GREEN}[✔] ${WHITE}$1${NC}"; }
warning() { echo -e "${YELLOW}[⚠] ${WHITE}$1${NC}"; }
error() { echo -e "${RED}[✖] ${WHITE}$1${NC}"; }
step() { echo -e "\n${MAGENTA}➤ ${CYAN}Step $1: ${WHITE}$2${NC}"; } 

# --- Animation Functions ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep -w $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r${MAGENTA} [%c] ${WHITE}Working... Please wait${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r\033[K" # Clear the spinner line completely
} 

typewriter() {
    local text="$1"
    local delay=0.015
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
} 

# --- Banner Function ---
show_banner() {
    clear
    echo -e "${MAGENTA}"
    echo '    █████╗ ██████╗ ██╗██╗  ██╗'
    echo '   ██╔══██╗██╔══██╗██║╚██╗██╔╝'
    echo '   ███████║██████╔╝██║ ╚███╔╝ '
    echo '   ██╔══██║██╔══██╗██║ ██╔██╗ '
    echo '   ██║  ██║██║  ██║██║██╔╝ ██╗'
    echo '   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
    typewriter "      Advanced Theme & Addon Installer"
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
} 

DOWNLOAD_URL=""
LICENSE_TYPE=""
LICENSE_VERSION=""
ACTION=""
LICENSE_VALID="false"


# ==========================================
# THEME INSTALLER FUNCTIONS
# ==========================================
check_dependencies() {
    info "Verifying Node.js and Yarn requirements..."
    set +e
    if command -v node >/dev/null 2>&1; then
        NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VER" -lt 22 ]; then
            warning "Node.js version is below 22. Updating to Node 22..."
            (curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 && apt-get install -y nodejs > /dev/null 2>&1) & spinner $!
        else
            success "Node.js v22+ is already installed."
        fi
    else
        warning "Node.js not found. Installing Node 22..."
        (curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 && apt-get install -y nodejs > /dev/null 2>&1) & spinner $!
    fi
    if ! command -v yarn >/dev/null 2>&1; then
        warning "Yarn not found. Installing Yarn..."
        (npm install -g yarn > /dev/null 2>&1) & spinner $!
        success "Yarn installed successfully."
    else
        success "Yarn is already installed."
    fi
    set -e
} 

verify_license() {
    local TYPE_REQ=$1
    local VERSION_REQ=$2
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${YELLOW}         🔒 SECURITY VERIFICATION REQUIRED    ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}\n"
    
    echo -ne "${MAGENTA} ➜ ${WHITE}Enter your Registered Email: ${CYAN}"
    read USER_EMAIL
    echo -ne "${MAGENTA} ➜ ${WHITE}Enter your License Key: ${CYAN}"
    read USER_KEY
    echo -ne "${NC}" 
    
    echo ""
    info "Establishing secure connection to licensing server..."
    
    USER_IP=$(curl -s ifconfig.me)
    RESPONSE=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\", \"key\":\"$USER_KEY\", \"ip\":\"$USER_IP\", \"requestedType\":\"$TYPE_REQ\", \"requestedVersion\":\"$VERSION_REQ\"}")
    
    if echo "$RESPONSE" | grep -qE '"success":\s*true'; then
        SUCCESS="true"
    else
        SUCCESS="false"
    fi
    MESSAGE=$(echo "$RESPONSE" | sed -n 's/.*"message"\s*:\s*"\([^"]*\)".*/\1/p')
    if [ -z "$MESSAGE" ]; then
        MESSAGE="Invalid response from the licensing server."
    fi 
    
    if [ "$SUCCESS" != "true" ]; then
        echo ""
        error "Authentication Denied: $MESSAGE"
        sleep 2
        LICENSE_VALID="false"
        return 0
    else
        echo ""
        success "License Verified! Authorization Granted."
        sleep 1.5
        LICENSE_VALID="true"
        return 0
    fi
} 

prompt_action() {
    local version=$1
    while true; do
        show_banner
        echo -e "${WHITE}Selected Theme: ${GREEN}Arix v${LICENSE_VERSION} (${LICENSE_TYPE})${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Install Theme"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Uninstall Theme"
        
        if [ "$version" == "2.1.0" ]; then
            echo -e "${CYAN}  [ 3 ] ${WHITE}Fix Issues"
            echo -e "${CYAN}  [ 4 ] ${WHITE}Go Back${NC}\n"
        else
            echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        fi
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an action: ${CYAN}"
        read act_choice
        echo -ne "${NC}"
        
        if [ "$version" == "2.1.0" ]; then
            case $act_choice in
                1) ACTION="install"; return 0 ;;
                2) ACTION="uninstall"; return 0 ;;
                3) ACTION="fix_issues"; return 0 ;;
                4) ACTION=""; return 1 ;;
                *) warning "Invalid selection."; sleep 1 ;;
            esac
        else
            case $act_choice in
                1) ACTION="install"; return 0 ;;
                2) ACTION="uninstall"; return 0 ;;
                3) ACTION=""; return 1 ;;
                *) warning "Invalid selection."; sleep 1 ;;
            esac
        fi
    done
}

menu_210() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.1.0${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_210
        echo -ne "${NC}"
        
        case $choice_210 in
            1) 
                LICENSE_TYPE="non-blueprint"
                LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v210/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi
                ;;
            2) 
                LICENSE_TYPE="blueprint"
                LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi
                ;;
            3) break ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
} 

menu_208() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.0.8${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_208
        echo -ne "${NC}"
        
        case $choice_208 in
            1) 
                LICENSE_TYPE="non-blueprint"
                LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v208/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi
                ;;
            2) 
                LICENSE_TYPE="blueprint"
                LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/av1pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi
                ;;
            3) break ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
} 

theme_installer_menu() {
    while true; do
        show_banner
        typewriter " Theme Installer - Select Version:"
        echo ""
        echo -e "${CYAN}  [ 1 ] ${WHITE}Arix v2.1.0 ${GREEN}(Latest)${NC}"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Arix v2.0.8 ${YELLOW}(Legacy)${NC}"
        echo -e "${RED}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read th_choice
        echo -ne "${NC}"
        
        case $th_choice in
            1) menu_210; if [ -n "$ACTION" ]; then return 0; fi ;;
            2) menu_208; if [ -n "$ACTION" ]; then return 0; fi ;;
            0) return 1 ;;
            *) echo ""; warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

execute_theme_action() {
    # ----------------------------------------------------
    # UNINSTALL PROCESS
    # ----------------------------------------------------
    if [ "$ACTION" == "uninstall" ]; then
        show_banner
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING UNINSTALLATION          ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl installation not found in /var/www/pterodactyl!"
            sleep 2
            return 0
        fi
        cd /var/www/pterodactyl 
        
        info "Running Arix Uninstall Process..."
        php artisan arix uninstall
        
        echo ""
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "     🗑️ UNINSTALLATION COMPLETED SUCCESSFULLY! 🗑️    "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo ""
        read -p "Press Enter to return to main menu..."
        return 0
    fi

    # ----------------------------------------------------
    # FIX ISSUES PROCESS
    # ----------------------------------------------------
    if [ "$ACTION" == "fix_issues" ]; then
        show_banner
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING FIX ISSUES              ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl installation not found in /var/www/pterodactyl!"
            sleep 2
            return 0
        fi
        cd /var/www/pterodactyl 
        
        # 1. RouterElements.tsx
        info "Fixing RouterElements.tsx..."
        rm -f resources/scripts/routers/RouterElements.tsx
        cat << 'EOF' > resources/scripts/routers/RouterElements.tsx
import React, { useEffect, useState, useMemo } from 'react';
import { ServerContext } from '@/state/server';
import routes from '@/routers/routes';
import { NavLink, Route, Switch, useRouteMatch } from 'react-router-dom';
import PermissionRoute from '@/components/elements/PermissionRoute';
import Spinner from '@/components/elements/Spinner';
import { NotFound, PremiumFeature } from '@/components/elements/ScreenBlock';
import TransitionRouter from '@/TransitionRouter';
import { useLocation } from 'react-router';
import { ApplicationStore } from '@/state';
import { useStoreState } from 'easy-peasy';
import Icon from '@/components/admin/elements/IconMap';
import Can from '@/components/elements/Can';
import { LinkCategory, LinkItem } from '@/api/admin/Link';
import { useTranslation } from 'react-i18next';
import { StarIcon } from '@heroicons/react/solid'; 

// --- BLUEPRINT IMPORTS ---
import blueprintRoutes from '@blueprint/extends/routers/routes';
import { HiOutlineAdjustments, HiAdjustments } from 'react-icons/hi';
import { LuSlidersVertical } from 'react-icons/lu';
import { RiSoundModuleLine, RiSoundModuleFill } from 'react-icons/ri'; 

// --- CUSTOM ICON IMPORTS ---
import { 
    FaEdit, FaGlobe, FaCogs, FaCodeBranch, FaBoxOpen, FaPlug, 
    FaMap, FaUsers, FaFileImport, FaPuzzlePiece, FaLayerGroup, 
    FaCube, FaRocket, FaBolt, FaTerminal, FaArchive, FaDatabase, FaCalendarAlt 
} from 'react-icons/fa';
// ------------------------- 

const ICON_MAP: Record<string, number> = {
    heroicons: 0,
    heroiconsFilled: 1,
    lucide: 2,
    remixicon: 3,
    remixiconFilled: 4,
};
// ------------------------- 

const shouldDisplayRoute = (route: any, nestId?: number, eggId?: number): boolean => {
    const hasNestMatch = route.nestIds?.includes(nestId ?? 0) || route.nestId === nestId;
    const hasEggMatch = route.eggIds?.includes(eggId ?? 0) || route.eggId === eggId;
    const hasNoRestrictions = !route.eggIds && !route.nestIds && !route.nestId && !route.eggId;
    return hasNestMatch || hasEggMatch || hasNoRestrictions;
}; 

const useServerIds = () => {
    const nestId = ServerContext.useStoreState((state) => state.server.data?.nestId);
    const eggId = ServerContext.useStoreState((state) => state.server.data?.eggId);
    const tier = ServerContext.useStoreState((state) => state.server.data?.tier); 

    return { nestId, eggId, tier };
}; 

const usePathBuilder = () => {
    const match = useRouteMatch<{ id: string }>();
    return (value: string, useUrl = false) => {
        const base = (useUrl ? match.url : match.path).replace(/\/*$/, '');
        return `${base}/${value.replace(/^\/+/, '')}`;
    };
}; 

const getAdjustedPath = (path: string, isDashboardDisabled: boolean) =>
    path === '/console' && isDashboardDisabled ? '/' : path; 

const Link = (props: LinkItem) => {
    const { t } = useTranslation('arix/navigation');
    const { nestId, eggId, tier } = useServerIds();
    const tierVisibility = useStoreState(
        (state: ApplicationStore) => state.settings.data?.arix?.advanced?.tierVisibility ?? 'show'
    ); 

    const permissions = (props.permission ?? []).filter((permission) => permission && permission.trim().length > 0);
    const hasPermissions = permissions.length > 0; 

    const hasNestRestrictions = Array.isArray(props.nests) && props.nests.length > 0;
    const hasEggRestrictions = Array.isArray(props.eggs) && props.eggs.length > 0;
    const hasTierRestrictions = Array.isArray(props.tier) && props.tier.length > 0; 

    const nestMatches = hasNestRestrictions && typeof nestId === 'number' && props.nests?.includes(nestId) === true;
    const eggMatches = hasEggRestrictions && typeof eggId === 'number' && props.eggs?.includes(eggId) === true;
    const tierMatches =
        hasTierRestrictions && tier !== null && tier !== undefined && props.tier?.includes(tier) === true; 

    const hasRestrictions = hasNestRestrictions || hasEggRestrictions || hasTierRestrictions; 

    const showStar =
        hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'show';
    const shouldHide =
        hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'hidden'; 

    const buildPath = usePathBuilder(); 

    if (hasRestrictions && !nestMatches && !eggMatches && shouldHide) {
        return null;
    } 

    const starIcon = showStar ? <StarIcon className='w-3 text-yellow-500' /> : null; 

    const linkContent = (
        <>
            <div className='routers_link_icon'>
                <Icon name={props.icon} size='1.25rem' />
            </div>
            <span className='routers_link_title'>{t(props.name)}</span>
            {starIcon}
        </>
    ); 

    const inner = props.url.includes('http') ? (
        <div className='relative'>
            <a key={props.name} href={props.url} target='_blank' rel='noreferrer' className='routers_link'>
                {linkContent}
            </a>
        </div>
    ) : (
        <div className='relative'>
            <NavLink
                key={props.name}
                to={buildPath(props.url, true)}
                exact={props.url === '/'}
                className='routers_link'
            >
                {linkContent}
            </NavLink>
        </div>
    ); 

    return hasPermissions ? (
        <Can action={permissions} matchAny>
            {inner}
        </Can>
    ) : (
        inner
    );
}; 

const Category = (props: LinkCategory) => {
    const { t } = useTranslation('arix/navigation');
    const { nestId, eggId } = useServerIds();
    const permissions = (props.permission ?? []).filter((permission) => permission && permission.trim().length > 0);
    const hasPermissions = permissions.length > 0;
    const hasNestRestrictions = Array.isArray(props.nests) && props.nests.length > 0;
    const hasEggRestrictions = Array.isArray(props.eggs) && props.eggs.length > 0;
    const nestMatches = hasNestRestrictions && typeof nestId === 'number' && props.nests?.includes(nestId) === true;
    const eggMatches = hasEggRestrictions && typeof eggId === 'number' && props.eggs?.includes(eggId) === true;
    const hasRestrictions = hasNestRestrictions || hasEggRestrictions; 

    if (hasRestrictions && !nestMatches && !eggMatches) {
        return null;
    } 

    return hasPermissions ? (
        <Can action={permissions} matchAny>
            <div key={props.name} className='routers_category-wrapper'>
                <span className='routers_category'>{t(props.name)}</span>
                <div className='routers_links'>
                    {props.links.map((link) => (
                        <Link key={link.name} {...link} />
                    ))}
                </div>
            </div>
        </Can>
    ) : (
        <div className='routers_category-wrapper'>
            <span className='routers_category'>{t(props.name)}</span>
            <div className='routers_links'>
                {props.links.map((link) => (
                    <Link key={link.name} {...link} />
                ))}
            </div>
        </div>
    );
}; 

// --- BLUEPRINT LOGIC INJECTION ---
const blueprintExtensions = [...new Set(blueprintRoutes.server.map((route) => route.identifier))]; 

const useExtensionEggs = () => {
    const [extensionEggs, setExtensionEggs] = useState<{ [x: string]: string[] }>(
        blueprintExtensions.reduce((prev, current) => ({ ...prev, [current]: ['-1'] }), {})
    ); 

    useEffect(() => {
        (async () => {
            const newEggs: { [x: string]: string[] } = {};
            for (const id of blueprintExtensions) {
                try {
                    const resp = await fetch(`/api/client/extensions/blueprint/eggs?${new URLSearchParams({ id })}`);
                    newEggs[id] = (await resp.json()) as string[];
                } catch (e) {
                    newEggs[id] = ['-1'];
                }
            }
            setExtensionEggs(newEggs);
        })();
    }, []); 

    return extensionEggs;
}; 

const useBlueprintServerRoutes = () => {
    const rootAdmin = useStoreState((state: ApplicationStore) => state.user.data?.rootAdmin ?? false);
    const serverEgg = ServerContext.useStoreState((state) => state.server.data?.BlueprintFramework?.eggId);
    const extensionEggs = useExtensionEggs(); 

    return useMemo(() => {
        return blueprintRoutes.server
            .filter((route) => !!route.name)
            .filter((route) => (route.adminOnly ? rootAdmin : true))
            .filter((route) => {
                const eggs = extensionEggs[route.identifier];
                if (!eggs) return false;
                return eggs.includes('-1') || eggs.includes(String(serverEgg));
            });
    }, [rootAdmin, serverEgg, extensionEggs]);
}; 

// --- GET FOOLPROOF ROUTE KEY ---
const getRouteKey = (route: any) => {
    return `${route.name || ''} ${route.path || ''} ${route.identifier || ''}`.toLowerCase();
};
// ------------------------------------------------------ 

const renderBlueprintIcon = (route: any, iconType: string) => {
    const key = getRouteKey(route); 

    if (key.includes('plugin')) return <FaPlug size="1.25rem" />;
    if (key.includes('mod')) return <FaBoxOpen size="1.25rem" />;
    if (key.includes('version')) return <FaCodeBranch size="1.25rem" />;
    if (key.includes('propert') || key.includes('setting')) return <FaCogs size="1.25rem" />;
    if (key.includes('player') || key.includes('user')) return <FaUsers size="1.25rem" />;
    if (key.includes('world') || key.includes('map')) return <FaMap size="1.25rem" />;
    if (key.includes('icon') || key.includes('import')) return <FaFileImport size="1.25rem" />;
    
    if (key.includes('motd')) return <FaEdit size="1.25rem" />;
    if (key.includes('subdomain') || key.includes('domain')) return <FaGlobe size="1.25rem" />;
    if (key.includes('backup') || key.includes('archive')) return <FaArchive size="1.25rem" />;
    if (key.includes('database') || key.includes('mysql')) return <FaDatabase size="1.25rem" />;
    if (key.includes('schedule') || key.includes('task')) return <FaCalendarAlt size="1.25rem" />; 

    const genericIcons = [
        <FaPuzzlePiece size="1.25rem" />, 
        <FaLayerGroup size="1.25rem" />, 
        <FaCube size="1.25rem" />, 
        <FaRocket size="1.25rem" />, 
        <FaBolt size="1.25rem" />, 
        <FaTerminal size="1.25rem" />
    ];
    
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
        hash = key.charCodeAt(i) + ((hash << 5) - hash);
    }
    return genericIcons[Math.abs(hash) % genericIcons.length];
}; 

const BlueprintLink = ({ route }: { route: any }) => {
    const buildPath = usePathBuilder();
    const iconType = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.icon ?? 'heroicons');
    const { t } = useTranslation('arix/navigation');
    
    const inner = (
        <NavLink
            to={buildPath(route.path, true)}
            exact={route.exact}
            className='routers_link'
        >
            <div className='routers_link_icon'>
                {renderBlueprintIcon(route, iconType)}
            </div>
            <span className='routers_link_title'>{t(route.name) || route.name}</span>
        </NavLink>
    ); 

    return route.permission ? (
        <Can action={route.permission} matchAny>
            {inner}
        </Can>
    ) : inner;
};
// --------------------------------- 

export const Navigation = () => {
    const links = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.links ?? {});
    const blueprintServerRoutes = useBlueprintServerRoutes(); 

    // --- IMPROVED SORTING LOGIC ---
    const sortedBlueprintRoutes = useMemo(() => {
        return [...blueprintServerRoutes].sort((a, b) => {
            const keyA = getRouteKey(a);
            const keyB = getRouteKey(b); 

            const getRank = (key: string) => {
                if (key.includes('plugin')) return 1;
                if (key.includes('mod')) return 2;
                if (key.includes('version')) return 3;
                if (key.includes('propert')) return 4;
                if (key.includes('player')) return 5;
                if (key.includes('world')) return 6;
                return 99; // বাকি সব (Icon Importer বা অন্য যা ইন্সটল করবে, সেগুলো এই ক্যাটাগরিতে পড়বে)
            }; 

            const rankA = getRank(keyA);
            const rankB = getRank(keyB); 

            if (rankA !== rankB) {
                return rankA - rankB;
            }
            return keyA.localeCompare(keyB);
        });
    }, [blueprintServerRoutes]);
    // ---------------------------- 

    return (
        <React.Fragment>
            {Object.values(links).map((category, index) => (
                <Category key={index} {...category} />
            ))} 

            {/* BLUEPRINT EXTENSIONS MENU */}
            {sortedBlueprintRoutes.length > 0 && (
                <div className='routers_category-wrapper'>
                    <span className='routers_category'>Extensions</span>
                    <div className='routers_links'>
                        {sortedBlueprintRoutes.map((route) => (
                            <BlueprintLink key={route.path} route={route} />
                        ))}
                    </div>
                </div>
            )}
        </React.Fragment>
    );
}; 

export const ComponentLoader = () => {
    const location = useLocation();
    const links = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.links ?? {});
    const dashboardPage = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.advanced?.dashboardPage ?? true);
    const { nestId, eggId, tier } = useServerIds();
    const buildPath = usePathBuilder();
    const blueprintServerRoutes = useBlueprintServerRoutes(); 

    const canShowWithTier = (routePath: string): boolean => {
        const link = Object.values(links ?? {})
            .flatMap((category) => category.links)
            .find((link) => link.url === routePath); 

        if (!link) return true;
        if (!Array.isArray(link.tier) || link.tier.length === 0) return true;
        if (tier == null) return true; 

        return link.tier.includes(tier);
    }; 

    return (
        <TransitionRouter>
            <Switch location={location}>
                {routes.server.map((route) => {
                    if (!shouldDisplayRoute(route, nestId, eggId)) return null;
                    if (route.path === '/' && !dashboardPage) return null; 

                    const path = getAdjustedPath(route.path, !dashboardPage);
                    const Component = route.component; 

                    if (!canShowWithTier(path)) return <PremiumFeature />; 

                    return (
                        <PermissionRoute key={path} permission={route.permission} path={buildPath(path)} exact>
                            <Spinner.Suspense>
                                <Component />
                            </Spinner.Suspense>
                        </PermissionRoute>
                    );
                })} 

                {/* BLUEPRINT COMPONENTS ROUTES */}
                {blueprintServerRoutes.map(({ path, permission, component: Component }) => (
                    <PermissionRoute key={path} permission={permission} path={buildPath(path)} exact>
                        <Spinner.Suspense>
                            <Component />
                        </Spinner.Suspense>
                    </PermissionRoute>
                ))} 

                <Route path={'*'} component={NotFound} />
            </Switch>
        </TransitionRouter>
    );
};
EOF
        success "RouterElements.tsx Replaced!"
        info "Running yarn add and compiling panel... (Please wait)"
        (
            yarn add xterm-addon-unicode11 > /dev/null 2>&1
            yarn build > /dev/null 2>&1
        ) & spinner $!

        # 2. DashboardRouter.tsx
        info "Fixing DashboardRouter.tsx..."
        rm -f resources/scripts/routers/DashboardRouter.tsx
        cat << 'EOF' > resources/scripts/routers/DashboardRouter.tsx
import React from 'react';
import { NavLink, Route, Switch, useLocation } from 'react-router-dom';
import DashboardContainer from '@/components/dashboard/dashboard/DashboardContainer';
import { NotFound } from '@/components/elements/ScreenBlock';
import TransitionRouter from '@/TransitionRouter';
import Spinner from '@/components/elements/Spinner';
import routes from '@/routers/routes'; 

import ContentContainer from '@/components/elements/ContentContainer';
import { CodeIcon, CogIcon, EyeIcon, KeyIcon, LockClosedIcon, UserIcon } from '@heroicons/react/outline';
import LayoutWrapper from './layouts/LayoutWrapper';
import Announcement from '@/components/elements/Announcement';
import { useStoreState } from 'easy-peasy';
import { ApplicationStore } from '@/state';
import { useTranslation } from 'react-i18next'; 

// --- BLUEPRINT IMPORTS ---
import BeforeSubNavigation from '@blueprint/components/Navigation/SubNavigation/BeforeSubNavigation';
import AdditionalAccountItems from '@blueprint/components/Navigation/SubNavigation/AdditionalAccountItems';
import AfterSubNavigation from '@blueprint/components/Navigation/SubNavigation/AfterSubNavigation';
import blueprintRoutes from '@blueprint/extends/routers/routes';
// ------------------------- 

export default () => {
    const { t } = useTranslation('arix/account'); 

    const position = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.announcement?.position ?? 'none');
    const location = useLocation(); 

    return (
        <LayoutWrapper>
            {position === 'top' && <Announcement />}
            {location.pathname.startsWith('/account') && (
                <div className='border-b border-gray-600 pt-6 px-4'>
                    <ContentContainer>
                        <div className={'flex items-center gap-x-3 mb-4'}>
                            <div
                                className={
                                    'w-10 h-10 bg-arix/30 rounded-component !border-none flex items-center justify-center text-arix'
                                }
                            >
                                <UserIcon className={'w-6'} />
                            </div>
                            <p className={'text-lg font-medium text-gray-300'}>{t('account-settings')}</p>
                        </div>
                        <div className='flex items-center gap-x-8'> 

                            {/* BLUEPRINT SUB-NAVIGATION INJECTED */}
                            <BeforeSubNavigation /> 

                            {/* ARIX DEFAULT MENUS */}
                            <NavLink
                                to={'/account'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                                exact
                            >
                                <CogIcon className={'w-5'} />
                                {t('general')}
                            </NavLink>
                            <NavLink
                                to={'/account/security'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <LockClosedIcon className={'w-5'} />
                                {t('security')}
                            </NavLink>
                            <NavLink
                                to={'/account/ssh-keys'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <KeyIcon className={'w-5'} />
                                {t('ssh-keys')}
                            </NavLink>
                            <NavLink
                                to={'/account/api-keys'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <CodeIcon className={'w-5'} />
                                {t('api-keys')}
                            </NavLink>
                            <NavLink
                                to={'/account/activity'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <EyeIcon className={'w-5'} />
                                {t('activity')}
                            </NavLink> 

                            {/* BLUEPRINT SUB-NAVIGATION INJECTED */}
                            <AdditionalAccountItems />
                            <AfterSubNavigation /> 

                        </div>
                    </ContentContainer>
                </div>
            )} 

            <TransitionRouter>
                <React.Suspense fallback={<Spinner centered />}>
                    <Switch location={location}>
                        <Route path={'/'} exact>
                            <DashboardContainer />
                        </Route>
                        {routes.account.map(({ path, component: Component }) => (
                            <Route key={path} path={`/account/${path}`.replace('//', '/')} exact>
                                <Component />
                            </Route>
                        ))} 

                        {/* BLUEPRINT ROUTES PROPERLY INJECTED IN ARIX UI */}
                        {(blueprintRoutes.account || []).map(({ path, component: Component }) => (
                            <Route key={path} path={`/account/${path}`.replace('//', '/')} exact>
                                <Component />
                            </Route>
                        ))} 

                        <Route path={'*'}>
                            <NotFound />
                        </Route>
                    </Switch>
                </React.Suspense>
            </TransitionRouter>
        </LayoutWrapper>
    );
};
EOF
        success "DashboardRouter.tsx Replaced!"
        info "Compiling panel... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!

        # 3. AppearanceWrapper.tsx
        info "Fixing AppearanceWrapper.tsx..."
        rm -f resources/scripts/components/dashboard/account/forms/AppearanceWrapper.tsx
        cat << 'EOF' > resources/scripts/components/dashboard/account/forms/AppearanceWrapper.tsx
import React, { useState, useEffect, ChangeEvent } from 'react';
import { useStoreState } from 'easy-peasy';
import { ApplicationStore } from '@/state';
import { useTranslation } from 'react-i18next';
import TitledGreyBox from '@/components/elements/TitledGreyBox';
import Switch from '@/components/elements/Switch';
import Select from '@/components/elements/Select';
import updateAccountLanguage from '@/api/account/updateAccountLanguage';
import { Button } from '@/components/elements/button/index';
import { DesktopComputerIcon, EyeIcon, MoonIcon, SunIcon } from '@heroicons/react/outline'; 

const AppearanceWrapper = () => {
    const { i18n } = useTranslation('arix/account');
    const [selectedLanguage, setSelectedLanguage] = useState(i18n.language); 

    const {
        modeToggler,
        defaultMode,
        langSwitch,
        languageOptions: languages,
    } = useStoreState((state: ApplicationStore) => state.settings.data!.arix.advanced); 

    const [theme, setTheme] = useState(() => localStorage.getItem('theme') || defaultMode || 'dark');
    const [isCompact, setIsCompact] = useState(() => localStorage.getItem('compactMode') === 'true');
    const [isPrivacyMode, setIsPrivacyMode] = useState(() => localStorage.getItem('privacyMode') === 'true');
    const [panelSounds, setPanelSounds] = useState(() => localStorage.getItem('panelSounds') === 'true');
    const [animations, setAnimations] = useState(() => localStorage.getItem('animations') === 'true'); 

    useEffect(() => {
        localStorage.setItem('theme', theme);
        document.body.classList.remove('lightmode', 'darkmode', 'oled', 'auto');
        if (theme === 'light') {
            document.body.classList.add('lightmode');
        } else if (theme === 'oled') {
            document.body.classList.add('oled');
        } else if (theme === 'auto') {
            document.body.classList.add('auto');
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            document.body.classList.toggle('lightmode', !prefersDark);
        }
    }, [theme]); 

    useEffect(() => {
        localStorage.setItem('compactMode', String(isCompact));
        document.body.classList.toggle('compact', isCompact);
    }, [isCompact]); 

    useEffect(() => {
        localStorage.setItem('privacyMode', String(isPrivacyMode));
        document.body.classList.toggle('privacy', isPrivacyMode);
    }, [isPrivacyMode]); 

    useEffect(() => {
        localStorage.setItem('panelSounds', String(panelSounds));
    }, [panelSounds]); 

    useEffect(() => {
        localStorage.setItem('animations', String(animations));
        document.body.classList.toggle('animationsDisabled', animations);
    }, [animations]); 

    const handleLanguageChange = (event: ChangeEvent<HTMLSelectElement>) => {
        const newLanguage = event.target.value; 

        updateAccountLanguage(newLanguage).then(() => {
            i18n.changeLanguage(newLanguage);
            setSelectedLanguage(newLanguage);
        });
    }; 

    useEffect(() => {
        setSelectedLanguage(i18n.language || 'en');
    }, [i18n.language]); 

    const ToggleRow = ({
        label,
        description,
        offLabel,
        onLabel,
        value,
        onToggle,
        name,
    }: {
        label: React.ReactNode;
        description: string;
        offLabel?: string;
        onLabel?: string;
        value: boolean;
        onToggle: (checked: boolean) => void;
        name: string;
    }) => (
        <div className={'flex justify-between items-center'}>
            <div>
                <p className={'text-gray-100 mb-1'}>{label}</p>
                <p className='text-sm text-gray-300'>{description}</p>
            </div>
            <div className={'flex gap-x-2 items-center'}>
                <span className={'text-sm text-gray-300'}>{offLabel ?? 'Off'}</span>
                <Switch name={name} onChange={() => onToggle(!value)} defaultChecked={value} />
                <span className={'text-sm text-gray-300'}>{onLabel ?? 'On'}</span>
            </div>
        </div>
    ); 

    return (
        <TitledGreyBox title={'Appearance'}>
            <div className='space-y-5'>
                {langSwitch && languages.length > 1 && (
                    <div className={'flex justify-between items-center'}>
                        <div className='flex-1'>
                            <p className={'text-gray-100 mb-1'}>Panel Language</p>
                            <p className='text-sm text-gray-300'>Use the panel in different languages</p>
                        </div>
                        <Select
                            value={selectedLanguage}
                            className={'!w-auto min-w-40 !pr-10'}
                            onChange={handleLanguageChange}
                        >
                            {languages.map((lang: { key: string; name: string }) => (
                                <option key={lang.key} value={lang.key}>
                                    {lang.name}
                                </option>
                            ))}
                        </Select>
                    </div>
                )}
                {modeToggler && (
                    <div className={'flex justify-between items-center'}>
                        <div className='flex-1'>
                            <p className={'text-gray-100 mb-1'}>Light/Dark Mode</p>
                            <p className='text-sm text-gray-300'>Choose the style that suits you best</p>
                        </div>
                        <Button.Text
                            className={`flex gap-1 !rounded-r-none min-w-20 ${theme === 'light' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('light')}
                        >
                            <SunIcon className='w-5' />
                            Light
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-none min-w-20 ${
                                theme === 'darkmode' ? '!bg-gray-500' : ''
                            }`}
                            onClick={() => setTheme('darkmode')}
                        >
                            <MoonIcon className='w-5' />
                            Dark
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-none min-w-20 ${theme === 'oled' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('oled')}
                        >
                            <EyeIcon className='w-5' />
                            Oled
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-l-none min-w-20 ${theme === 'auto' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('auto')}
                        >
                            <DesktopComputerIcon className='w-5' />
                            Auto
                        </Button.Text>
                    </div>
                )}
                <ToggleRow
                    label={'Display Mode'}
                    description={'Toggle between normal and compact display modes'}
                    value={isCompact}
                    onToggle={setIsCompact}
                    onLabel={'Compact'}
                    offLabel={'Normal'}
                    name={'compact'}
                />
                <ToggleRow
                    label={'Panel Sounds'}
                    description={'Play a sound at crucial moments in the panel'}
                    value={panelSounds}
                    onToggle={setPanelSounds}
                    name={'panel-sounds'}
                />
                <ToggleRow
                    label={'Privacy Mode'}
                    description={'Hide sensitive information in the panel'}
                    value={isPrivacyMode}
                    onToggle={setIsPrivacyMode}
                    name={'privacy'}
                />
                <ToggleRow
                    label={'Animations'}
                    description={'Enable or disable animations in the panel'}
                    value={animations}
                    onToggle={setAnimations}
                    name={'animations'}
                />
            </div>
        </TitledGreyBox>
    );
}; 

export default AppearanceWrapper; 
EOF
        success "AppearanceWrapper.tsx Replaced!"
        info "Compiling panel... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!

        # 4. RegisterController.php
        info "Fixing RegisterController.php..."
        rm -f app/Http/Controllers/Auth/RegisterController.php
        cat << 'EOF' > app/Http/Controllers/Auth/RegisterController.php
<?php 

namespace Pterodactyl\Http\Controllers\Auth; 

use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\ModelNotFoundException; 

class RegisterController extends AbstractRegisterController
{
    /**
     * Handle all incoming requests for the authentication routes and render the
     * base authentication view component. React will take over at this point and
     * turn the register area into an SPA.
     */
    public function index(): View
    {
        return view('templates/auth.core');
    } 

    /**
     * Handle a register request to the application.
     *
     * @throws \Pterodactyl\Exceptions\DisplayException
     * @throws \Illuminate\Validation\ValidationException
     */
    public function register(Request $request): JsonResponse
    {
        if ($this->hasTooManyLoginAttempts($request)) {
            $this->fireLockoutEvent($request);
            $this->sendLockoutResponse($request);
        } 

        try {
            $user = User::where('email', $request->input('email'))->orWhere('username', $request->input('username'))->first(); 

            if ($user) {
                return response()->json(['error' => 'The email or username is already taken.'], 400);
            }
        } catch (ModelNotFoundException) {
            $this->sendFailedRegisterResponse($request);
        } 

        return $this->sendRegisterResponse($request);
    }
}
EOF
        success "RegisterController.php Replaced!"
        info "Compiling panel final step... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!
        
        echo ""
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "      🛠️ FIX ISSUES APPLIED SUCCESSFULLY! 🛠️      "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo ""
        read -p "Press Enter to return to main menu..."
        return 0
    fi

    # ----------------------------------------------------
    # INSTALL PROCESS (EXACTLY AS ORIGINAL CODE)
    # ----------------------------------------------------
    if [ "$ACTION" == "install" ]; then
        show_banner
        verify_license "$LICENSE_TYPE" "$LICENSE_VERSION"
        
        if [ "$LICENSE_VALID" == "false" ]; then
            return 0
        fi

        show_banner 

        check_dependencies 

        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING INSTALLATION            ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        set +e
        (apt-get update -y > /dev/null 2>&1 && apt-get install -y unzip curl wget > /dev/null 2>&1) & spinner $!
        set -e 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl installation not found in /var/www/pterodactyl!"
            sleep 2
            return 0
        fi
        cd /var/www/pterodactyl 

        step "1/4" "Downloading Arix Theme Assets (v$LICENSE_VERSION - $LICENSE_TYPE)..."
        (curl -sL -o pterodactyl.zip "$DOWNLOAD_URL") & spinner $!
        success "Downloaded successfully." 

        step "2/4" "Extracting Core Files..."
        (
            unzip -o pterodactyl.zip > /dev/null 2>&1
            if [ -d "pterodactyl" ]; then 
                cp -rf pterodactyl/* ./ 
                rm -rf pterodactyl 
            fi
            rm pterodactyl.zip 
        ) & spinner $!
        success "Files extracted successfully." 

        step "3/4" "Injecting Modules..."
        if [ "$LICENSE_VERSION" == "2.1.0" ]; then
            info "Applying Arix Patch Modules for v2.1.0..."
            cat << 'EOF' > app/Console/Commands/Arix.php
<?php 

namespace Pterodactyl\Console\Commands; 

use Illuminate\Console\Command;
use Symfony\Component\Console\Formatter\OutputFormatterStyle;
use Illuminate\Support\Facades\File; 

class Arix extends Command
{
    protected $signature = "arix {action?}";
    protected $description = "All commands for Arix Theme for Pterodactyl."; 

    public function handle()
    {
        $action = $this->argument("action");
        $title = new OutputFormatterStyle("#fff", null, ["bold"]);
        $this->output->getFormatter()->setStyle("title", $title);
        $b = new OutputFormatterStyle(null, null, ["bold"]);
        $this->output->getFormatter()->setStyle("b", $b); 

        if ($action === null) {
            $this->line("\r\n            <title>\r\n            ░█████╗░██████╗░██╗██╗░░██╗\r\n            ██╔══██╗██╔══██╗██║╚██╗██╔╝\r\n            ███████║██████╔╝██║░╚███╔╝░\r\n            ██╔══██║██╔══██╗██║░██╔██╗░\r\n            ██║░░██║██║░░██║██║██╔╝╚██╗\r\n            ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚═╝\r\n\r\n           Thank you for purchasing Arix</title>\r\n\r\n           > php artisan arix (this window)\r\n           > php artisan arix install\r\n           > php artisan arix update\r\n           > php artisan arix uninstall\r\n            ");
        } else {
            $this->info("\n    Arix Theme\n    \n");
            if ($action === "install") {
                $this->install();
            } elseif ($action === "update") {
                $this->update();
            } elseif ($action === "uninstall") {
                $this->uninstall();
            } else {
                $this->error("Invalid action. Supported actions: install, update, uninstall");
            }
        }
    } 

    public function installOrUpdate($isUpdate = false)
    {
        if ($isUpdate) {
            $this->info("\n    This command is not recommended to use. \n   This command skips frequently used files by addons during theme updating to avoid losing your addon customizations.\n   If you still experience an error after updating please contact us.");
        } 

        $confirmation = $this->confirm("Are all the required dependencies installed from the readme file?", "yes");
        if (!$confirmation) {
            return;
        } 

        $versions = File::directories("./arix");
        if (empty($versions)) {
            $this->info("No versions found in /arix directory.");
            return;
        } 

        $version = basename($this->choice("Select a version:", $versions));
        $this->info("Installing Arix Theme {$version}..."); 

        $excludeOption = $isUpdate ? "--exclude='routes.ts' --exclude='getServer.ts' --exclude='admin.blade.php' --exclude='admin.php' --exclude='ServerTransformer.php'" : '';
        exec("rsync -a {$excludeOption} arix/{$version}/ ./"); 

        $directoryPath = app_path("Http/Controllers/Admin/Arix");
        File::makeDirectory($directoryPath, 0755, true, true); 

        $filesOne = ["ArixController", "ArixAdvancedController", "ArixAnnouncementController", "ArixColorsController", "ArixComponentsController", "ArixDashboardController", "ArixLayoutController"];
        $this->info("Proceeding with the installation...");
        foreach ($filesOne as $file) {
            $this->aa($file, $version, $directoryPath);
            sleep(1);
        } 

        $filesTwo = ["ArixLinkController", "ArixMailController", "ArixMetaController", "ArixPresetController", "ArixSocialController", "ArixStylingController"];
        foreach ($filesTwo as $file) {
            $this->aa($file, $version, $directoryPath);
            sleep(1);
        } 

        $this->info("Migrating database...");
        $this->command("php artisan migrate --force"); 

        $this->info("Installing required packages...");
        $this->info("This can take a minute...");
        $this->command("yarn add react-email-editor react-colorful recharts@^2.15.4 ua-parser-js cronstrue react-day-picker jszip react-turnstile @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @types/md5 md5 react-icons@5.4.0 markdown-to-jsx@7.7.10 i18next-browser-languagedetector@7.2.1"); 

        $this->info("Compile translations...");
        $this->command("php artisan language:compile"); 

        $this->info("Building panel assets...");
        $this->info("This can take a minute...");
        $nodeVersion = shell_exec("node -v");
        $nodeVersion = (int) ltrim($nodeVersion, "v");
        if ($nodeVersion >= 17) {
            $this->info("Node.js version is v" . $nodeVersion . " (>= 17)");
            putenv("NODE_OPTIONS=--openssl-legacy-provider");
        } else {
            $this->info("Node.js version is v" . $nodeVersion . " (< 17)");
        }
        $this->command("yarn build:production"); 

        $this->info("Set permissions...");
        $this->command("chown -R www-data:www-data /var/www/pterodactyl/* " . base_path() . "/*");
        $this->command("chown -R nginx:nginx " . base_path() . "/*");
        $this->command("chown -R apache:apache " . base_path() . "/*"); 

        $this->info("Optimize application...");
        $this->command("php artisan optimize:clear");
        $this->command("php artisan optimize"); 

        $this->info("Restarting workers...");
        $this->command("php artisan queue:restart"); 

        $message = $isUpdate ? "│    Theme updated successfully   │" : "│   Theme installed successfully  │";
        $this->line("\n ╭───────────────────────────────╮\n │ │\n │ ╭─╴ {$message} ╶─╮ │\n │ ╰─╴ successfully ╶─╯ │\n │ │\n ╰───────────────────────────────╯\n ");
    } 

    private function aa($filename, $version, $directoryPath)
    {
        $filePath = $directoryPath . "/" . $filename . ".php";
        $localSource = base_path("arix/" . $version . "/app/Http/Controllers/Admin/Arix/" . $filename . ".php"); 

        if (File::exists($localSource)) {
            $this->info(" -> Copying local {$filename}.php...");
            File::copy($localSource, $filePath);
        } else {
            $this->error("Fail: Could not find local {$filename}.php at {$localSource}.");
        }
    }
    
    public function install()
    {
        $this->info("Configuring environment...");
        sleep(1);
        $this->info("Loading modules...");
        sleep(1);
        
        $this->installOrUpdate();
        
        $this->info("Arix Theme installation completed safely!");
    } 

    public function update()
    {
        $this->installOrUpdate(true);
    } 

    private function uninstall()
    {
        $this->line("Uninstalling...");
        $this->command("php artisan down");
        $this->command("curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv");
        $this->command("chmod -R 755 storage/* bootstrap/cache");
        $this->command("composer install --no-dev --optimize-autoloader");
        $this->command("php artisan view:clear");
        $this->command("php artisan config:clear");
        $this->command("php artisan migrate --seed --force");
        $this->command("chown -R www-data:www-data " . base_path() . "/*");
        $this->command("chown -R nginx:nginx " . base_path() . "/*");
        $this->command("chown -R apache:apache " . base_path() . "/*");
        $this->command("php artisan queue:restart");
        $this->command("php artisan up");
        $this->info("Arix Theme uninstalled successfully.");
    } 

    private function command($cmd)
    {
        return exec($cmd);
    }
}
EOF
            php artisan arix install
        else
            info "Skipping Arix.php patch for legacy v2.0.8..."
        fi
        success "Modules injected!" 

        step "4/4" "Compiling Pterodactyl Panel (Production Build)..."
        warning "This process takes 2-5 minutes. Please DO NOT close the terminal."
        (
            yarn add xterm-addon-unicode11 > /dev/null 2>&1
            yarn build > /dev/null 2>&1
        ) & spinner $!
        success "Panel compiled successfully!" 

        set +e 

        info "Applying Final Permissions & Caching..."
        (
            curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php > /dev/null 2>&1
            chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null
            chown -R nginx:nginx /var/www/pterodactyl 2>/dev/null
            find /var/www/pterodactyl -type d -exec chmod 755 {} \;
            find /var/www/pterodactyl -type f -exec chmod 644 {} \;
            chmod -R 775 storage/* bootstrap/cache/
            chown -R www-data:www-data /var/www/pterodactyl/*
        ) & spinner $! 
cd /var/www/pterodactyl 
        
        # 1. RouterElements.tsx
        info "Fixing RouterElements.tsx..."
        rm -f resources/scripts/routers/RouterElements.tsx
        cat << 'EOF' > resources/scripts/routers/RouterElements.tsx
import React, { useEffect, useState, useMemo } from 'react';
import { ServerContext } from '@/state/server';
import routes from '@/routers/routes';
import { NavLink, Route, Switch, useRouteMatch } from 'react-router-dom';
import PermissionRoute from '@/components/elements/PermissionRoute';
import Spinner from '@/components/elements/Spinner';
import { NotFound, PremiumFeature } from '@/components/elements/ScreenBlock';
import TransitionRouter from '@/TransitionRouter';
import { useLocation } from 'react-router';
import { ApplicationStore } from '@/state';
import { useStoreState } from 'easy-peasy';
import Icon from '@/components/admin/elements/IconMap';
import Can from '@/components/elements/Can';
import { LinkCategory, LinkItem } from '@/api/admin/Link';
import { useTranslation } from 'react-i18next';
import { StarIcon } from '@heroicons/react/solid'; 

// --- BLUEPRINT IMPORTS ---
import blueprintRoutes from '@blueprint/extends/routers/routes';
import { HiOutlineAdjustments, HiAdjustments } from 'react-icons/hi';
import { LuSlidersVertical } from 'react-icons/lu';
import { RiSoundModuleLine, RiSoundModuleFill } from 'react-icons/ri'; 

// --- CUSTOM ICON IMPORTS ---
import { 
    FaEdit, FaGlobe, FaCogs, FaCodeBranch, FaBoxOpen, FaPlug, 
    FaMap, FaUsers, FaFileImport, FaPuzzlePiece, FaLayerGroup, 
    FaCube, FaRocket, FaBolt, FaTerminal, FaArchive, FaDatabase, FaCalendarAlt 
} from 'react-icons/fa';
// ------------------------- 

const ICON_MAP: Record<string, number> = {
    heroicons: 0,
    heroiconsFilled: 1,
    lucide: 2,
    remixicon: 3,
    remixiconFilled: 4,
};
// ------------------------- 

const shouldDisplayRoute = (route: any, nestId?: number, eggId?: number): boolean => {
    const hasNestMatch = route.nestIds?.includes(nestId ?? 0) || route.nestId === nestId;
    const hasEggMatch = route.eggIds?.includes(eggId ?? 0) || route.eggId === eggId;
    const hasNoRestrictions = !route.eggIds && !route.nestIds && !route.nestId && !route.eggId;
    return hasNestMatch || hasEggMatch || hasNoRestrictions;
}; 

const useServerIds = () => {
    const nestId = ServerContext.useStoreState((state) => state.server.data?.nestId);
    const eggId = ServerContext.useStoreState((state) => state.server.data?.eggId);
    const tier = ServerContext.useStoreState((state) => state.server.data?.tier); 

    return { nestId, eggId, tier };
}; 

const usePathBuilder = () => {
    const match = useRouteMatch<{ id: string }>();
    return (value: string, useUrl = false) => {
        const base = (useUrl ? match.url : match.path).replace(/\/*$/, '');
        return `${base}/${value.replace(/^\/+/, '')}`;
    };
}; 

const getAdjustedPath = (path: string, isDashboardDisabled: boolean) =>
    path === '/console' && isDashboardDisabled ? '/' : path; 

const Link = (props: LinkItem) => {
    const { t } = useTranslation('arix/navigation');
    const { nestId, eggId, tier } = useServerIds();
    const tierVisibility = useStoreState(
        (state: ApplicationStore) => state.settings.data?.arix?.advanced?.tierVisibility ?? 'show'
    ); 

    const permissions = (props.permission ?? []).filter((permission) => permission && permission.trim().length > 0);
    const hasPermissions = permissions.length > 0; 

    const hasNestRestrictions = Array.isArray(props.nests) && props.nests.length > 0;
    const hasEggRestrictions = Array.isArray(props.eggs) && props.eggs.length > 0;
    const hasTierRestrictions = Array.isArray(props.tier) && props.tier.length > 0; 

    const nestMatches = hasNestRestrictions && typeof nestId === 'number' && props.nests?.includes(nestId) === true;
    const eggMatches = hasEggRestrictions && typeof eggId === 'number' && props.eggs?.includes(eggId) === true;
    const tierMatches =
        hasTierRestrictions && tier !== null && tier !== undefined && props.tier?.includes(tier) === true; 

    const hasRestrictions = hasNestRestrictions || hasEggRestrictions || hasTierRestrictions; 

    const showStar =
        hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'show';
    const shouldHide =
        hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'hidden'; 

    const buildPath = usePathBuilder(); 

    if (hasRestrictions && !nestMatches && !eggMatches && shouldHide) {
        return null;
    } 

    const starIcon = showStar ? <StarIcon className='w-3 text-yellow-500' /> : null; 

    const linkContent = (
        <>
            <div className='routers_link_icon'>
                <Icon name={props.icon} size='1.25rem' />
            </div>
            <span className='routers_link_title'>{t(props.name)}</span>
            {starIcon}
        </>
    ); 

    const inner = props.url.includes('http') ? (
        <div className='relative'>
            <a key={props.name} href={props.url} target='_blank' rel='noreferrer' className='routers_link'>
                {linkContent}
            </a>
        </div>
    ) : (
        <div className='relative'>
            <NavLink
                key={props.name}
                to={buildPath(props.url, true)}
                exact={props.url === '/'}
                className='routers_link'
            >
                {linkContent}
            </NavLink>
        </div>
    ); 

    return hasPermissions ? (
        <Can action={permissions} matchAny>
            {inner}
        </Can>
    ) : (
        inner
    );
}; 

const Category = (props: LinkCategory) => {
    const { t } = useTranslation('arix/navigation');
    const { nestId, eggId } = useServerIds();
    const permissions = (props.permission ?? []).filter((permission) => permission && permission.trim().length > 0);
    const hasPermissions = permissions.length > 0;
    const hasNestRestrictions = Array.isArray(props.nests) && props.nests.length > 0;
    const hasEggRestrictions = Array.isArray(props.eggs) && props.eggs.length > 0;
    const nestMatches = hasNestRestrictions && typeof nestId === 'number' && props.nests?.includes(nestId) === true;
    const eggMatches = hasEggRestrictions && typeof eggId === 'number' && props.eggs?.includes(eggId) === true;
    const hasRestrictions = hasNestRestrictions || hasEggRestrictions; 

    if (hasRestrictions && !nestMatches && !eggMatches) {
        return null;
    } 

    return hasPermissions ? (
        <Can action={permissions} matchAny>
            <div key={props.name} className='routers_category-wrapper'>
                <span className='routers_category'>{t(props.name)}</span>
                <div className='routers_links'>
                    {props.links.map((link) => (
                        <Link key={link.name} {...link} />
                    ))}
                </div>
            </div>
        </Can>
    ) : (
        <div className='routers_category-wrapper'>
            <span className='routers_category'>{t(props.name)}</span>
            <div className='routers_links'>
                {props.links.map((link) => (
                    <Link key={link.name} {...link} />
                ))}
            </div>
        </div>
    );
}; 

// --- BLUEPRINT LOGIC INJECTION ---
const blueprintExtensions = [...new Set(blueprintRoutes.server.map((route) => route.identifier))]; 

const useExtensionEggs = () => {
    const [extensionEggs, setExtensionEggs] = useState<{ [x: string]: string[] }>(
        blueprintExtensions.reduce((prev, current) => ({ ...prev, [current]: ['-1'] }), {})
    ); 

    useEffect(() => {
        (async () => {
            const newEggs: { [x: string]: string[] } = {};
            for (const id of blueprintExtensions) {
                try {
                    const resp = await fetch(`/api/client/extensions/blueprint/eggs?${new URLSearchParams({ id })}`);
                    newEggs[id] = (await resp.json()) as string[];
                } catch (e) {
                    newEggs[id] = ['-1'];
                }
            }
            setExtensionEggs(newEggs);
        })();
    }, []); 

    return extensionEggs;
}; 

const useBlueprintServerRoutes = () => {
    const rootAdmin = useStoreState((state: ApplicationStore) => state.user.data?.rootAdmin ?? false);
    const serverEgg = ServerContext.useStoreState((state) => state.server.data?.BlueprintFramework?.eggId);
    const extensionEggs = useExtensionEggs(); 

    return useMemo(() => {
        return blueprintRoutes.server
            .filter((route) => !!route.name)
            .filter((route) => (route.adminOnly ? rootAdmin : true))
            .filter((route) => {
                const eggs = extensionEggs[route.identifier];
                if (!eggs) return false;
                return eggs.includes('-1') || eggs.includes(String(serverEgg));
            });
    }, [rootAdmin, serverEgg, extensionEggs]);
}; 

// --- GET FOOLPROOF ROUTE KEY ---
const getRouteKey = (route: any) => {
    return `${route.name || ''} ${route.path || ''} ${route.identifier || ''}`.toLowerCase();
};
// ------------------------------------------------------ 

const renderBlueprintIcon = (route: any, iconType: string) => {
    const key = getRouteKey(route); 

    if (key.includes('plugin')) return <FaPlug size="1.25rem" />;
    if (key.includes('mod')) return <FaBoxOpen size="1.25rem" />;
    if (key.includes('version')) return <FaCodeBranch size="1.25rem" />;
    if (key.includes('propert') || key.includes('setting')) return <FaCogs size="1.25rem" />;
    if (key.includes('player') || key.includes('user')) return <FaUsers size="1.25rem" />;
    if (key.includes('world') || key.includes('map')) return <FaMap size="1.25rem" />;
    if (key.includes('icon') || key.includes('import')) return <FaFileImport size="1.25rem" />;
    
    if (key.includes('motd')) return <FaEdit size="1.25rem" />;
    if (key.includes('subdomain') || key.includes('domain')) return <FaGlobe size="1.25rem" />;
    if (key.includes('backup') || key.includes('archive')) return <FaArchive size="1.25rem" />;
    if (key.includes('database') || key.includes('mysql')) return <FaDatabase size="1.25rem" />;
    if (key.includes('schedule') || key.includes('task')) return <FaCalendarAlt size="1.25rem" />; 

    const genericIcons = [
        <FaPuzzlePiece size="1.25rem" />, 
        <FaLayerGroup size="1.25rem" />, 
        <FaCube size="1.25rem" />, 
        <FaRocket size="1.25rem" />, 
        <FaBolt size="1.25rem" />, 
        <FaTerminal size="1.25rem" />
    ];
    
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
        hash = key.charCodeAt(i) + ((hash << 5) - hash);
    }
    return genericIcons[Math.abs(hash) % genericIcons.length];
}; 

const BlueprintLink = ({ route }: { route: any }) => {
    const buildPath = usePathBuilder();
    const iconType = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.icon ?? 'heroicons');
    const { t } = useTranslation('arix/navigation');
    
    const inner = (
        <NavLink
            to={buildPath(route.path, true)}
            exact={route.exact}
            className='routers_link'
        >
            <div className='routers_link_icon'>
                {renderBlueprintIcon(route, iconType)}
            </div>
            <span className='routers_link_title'>{t(route.name) || route.name}</span>
        </NavLink>
    ); 

    return route.permission ? (
        <Can action={route.permission} matchAny>
            {inner}
        </Can>
    ) : inner;
};
// --------------------------------- 

export const Navigation = () => {
    const links = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.links ?? {});
    const blueprintServerRoutes = useBlueprintServerRoutes(); 

    // --- IMPROVED SORTING LOGIC ---
    const sortedBlueprintRoutes = useMemo(() => {
        return [...blueprintServerRoutes].sort((a, b) => {
            const keyA = getRouteKey(a);
            const keyB = getRouteKey(b); 

            const getRank = (key: string) => {
                if (key.includes('plugin')) return 1;
                if (key.includes('mod')) return 2;
                if (key.includes('version')) return 3;
                if (key.includes('propert')) return 4;
                if (key.includes('player')) return 5;
                if (key.includes('world')) return 6;
                return 99; // বাকি সব (Icon Importer বা অন্য যা ইন্সটল করবে, সেগুলো এই ক্যাটাগরিতে পড়বে)
            }; 

            const rankA = getRank(keyA);
            const rankB = getRank(keyB); 

            if (rankA !== rankB) {
                return rankA - rankB;
            }
            return keyA.localeCompare(keyB);
        });
    }, [blueprintServerRoutes]);
    // ---------------------------- 

    return (
        <React.Fragment>
            {Object.values(links).map((category, index) => (
                <Category key={index} {...category} />
            ))} 

            {/* BLUEPRINT EXTENSIONS MENU */}
            {sortedBlueprintRoutes.length > 0 && (
                <div className='routers_category-wrapper'>
                    <span className='routers_category'>Extensions</span>
                    <div className='routers_links'>
                        {sortedBlueprintRoutes.map((route) => (
                            <BlueprintLink key={route.path} route={route} />
                        ))}
                    </div>
                </div>
            )}
        </React.Fragment>
    );
}; 

export const ComponentLoader = () => {
    const location = useLocation();
    const links = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.links ?? {});
    const dashboardPage = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.advanced?.dashboardPage ?? true);
    const { nestId, eggId, tier } = useServerIds();
    const buildPath = usePathBuilder();
    const blueprintServerRoutes = useBlueprintServerRoutes(); 

    const canShowWithTier = (routePath: string): boolean => {
        const link = Object.values(links ?? {})
            .flatMap((category) => category.links)
            .find((link) => link.url === routePath); 

        if (!link) return true;
        if (!Array.isArray(link.tier) || link.tier.length === 0) return true;
        if (tier == null) return true; 

        return link.tier.includes(tier);
    }; 

    return (
        <TransitionRouter>
            <Switch location={location}>
                {routes.server.map((route) => {
                    if (!shouldDisplayRoute(route, nestId, eggId)) return null;
                    if (route.path === '/' && !dashboardPage) return null; 

                    const path = getAdjustedPath(route.path, !dashboardPage);
                    const Component = route.component; 

                    if (!canShowWithTier(path)) return <PremiumFeature />; 

                    return (
                        <PermissionRoute key={path} permission={route.permission} path={buildPath(path)} exact>
                            <Spinner.Suspense>
                                <Component />
                            </Spinner.Suspense>
                        </PermissionRoute>
                    );
                })} 

                {/* BLUEPRINT COMPONENTS ROUTES */}
                {blueprintServerRoutes.map(({ path, permission, component: Component }) => (
                    <PermissionRoute key={path} permission={permission} path={buildPath(path)} exact>
                        <Spinner.Suspense>
                            <Component />
                        </Spinner.Suspense>
                    </PermissionRoute>
                ))} 

                <Route path={'*'} component={NotFound} />
            </Switch>
        </TransitionRouter>
    );
};
EOF
        success "RouterElements.tsx Replaced!"
        info "Running yarn add and compiling panel... (Please wait)"
        (
            yarn add xterm-addon-unicode11 > /dev/null 2>&1
            yarn build > /dev/null 2>&1
        ) & spinner $!

        # 2. DashboardRouter.tsx
        info "Fixing DashboardRouter.tsx..."
        rm -f resources/scripts/routers/DashboardRouter.tsx
        cat << 'EOF' > resources/scripts/routers/DashboardRouter.tsx
import React from 'react';
import { NavLink, Route, Switch, useLocation } from 'react-router-dom';
import DashboardContainer from '@/components/dashboard/dashboard/DashboardContainer';
import { NotFound } from '@/components/elements/ScreenBlock';
import TransitionRouter from '@/TransitionRouter';
import Spinner from '@/components/elements/Spinner';
import routes from '@/routers/routes'; 

import ContentContainer from '@/components/elements/ContentContainer';
import { CodeIcon, CogIcon, EyeIcon, KeyIcon, LockClosedIcon, UserIcon } from '@heroicons/react/outline';
import LayoutWrapper from './layouts/LayoutWrapper';
import Announcement from '@/components/elements/Announcement';
import { useStoreState } from 'easy-peasy';
import { ApplicationStore } from '@/state';
import { useTranslation } from 'react-i18next'; 

// --- BLUEPRINT IMPORTS ---
import BeforeSubNavigation from '@blueprint/components/Navigation/SubNavigation/BeforeSubNavigation';
import AdditionalAccountItems from '@blueprint/components/Navigation/SubNavigation/AdditionalAccountItems';
import AfterSubNavigation from '@blueprint/components/Navigation/SubNavigation/AfterSubNavigation';
import blueprintRoutes from '@blueprint/extends/routers/routes';
// ------------------------- 

export default () => {
    const { t } = useTranslation('arix/account'); 

    const position = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.announcement?.position ?? 'none');
    const location = useLocation(); 

    return (
        <LayoutWrapper>
            {position === 'top' && <Announcement />}
            {location.pathname.startsWith('/account') && (
                <div className='border-b border-gray-600 pt-6 px-4'>
                    <ContentContainer>
                        <div className={'flex items-center gap-x-3 mb-4'}>
                            <div
                                className={
                                    'w-10 h-10 bg-arix/30 rounded-component !border-none flex items-center justify-center text-arix'
                                }
                            >
                                <UserIcon className={'w-6'} />
                            </div>
                            <p className={'text-lg font-medium text-gray-300'}>{t('account-settings')}</p>
                        </div>
                        <div className='flex items-center gap-x-8'> 

                            {/* BLUEPRINT SUB-NAVIGATION INJECTED */}
                            <BeforeSubNavigation /> 

                            {/* ARIX DEFAULT MENUS */}
                            <NavLink
                                to={'/account'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                                exact
                            >
                                <CogIcon className={'w-5'} />
                                {t('general')}
                            </NavLink>
                            <NavLink
                                to={'/account/security'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <LockClosedIcon className={'w-5'} />
                                {t('security')}
                            </NavLink>
                            <NavLink
                                to={'/account/ssh-keys'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <KeyIcon className={'w-5'} />
                                {t('ssh-keys')}
                            </NavLink>
                            <NavLink
                                to={'/account/api-keys'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <CodeIcon className={'w-5'} />
                                {t('api-keys')}
                            </NavLink>
                            <NavLink
                                to={'/account/activity'}
                                className={
                                    'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'
                                }
                                activeClassName={'!border-arix text-gray-100'}
                            >
                                <EyeIcon className={'w-5'} />
                                {t('activity')}
                            </NavLink> 

                            {/* BLUEPRINT SUB-NAVIGATION INJECTED */}
                            <AdditionalAccountItems />
                            <AfterSubNavigation /> 

                        </div>
                    </ContentContainer>
                </div>
            )} 

            <TransitionRouter>
                <React.Suspense fallback={<Spinner centered />}>
                    <Switch location={location}>
                        <Route path={'/'} exact>
                            <DashboardContainer />
                        </Route>
                        {routes.account.map(({ path, component: Component }) => (
                            <Route key={path} path={`/account/${path}`.replace('//', '/')} exact>
                                <Component />
                            </Route>
                        ))} 

                        {/* BLUEPRINT ROUTES PROPERLY INJECTED IN ARIX UI */}
                        {(blueprintRoutes.account || []).map(({ path, component: Component }) => (
                            <Route key={path} path={`/account/${path}`.replace('//', '/')} exact>
                                <Component />
                            </Route>
                        ))} 

                        <Route path={'*'}>
                            <NotFound />
                        </Route>
                    </Switch>
                </React.Suspense>
            </TransitionRouter>
        </LayoutWrapper>
    );
};
EOF
        success "DashboardRouter.tsx Replaced!"
        info "Compiling panel... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!

        # 3. AppearanceWrapper.tsx
        info "Fixing AppearanceWrapper.tsx..."
        rm -f resources/scripts/components/dashboard/account/forms/AppearanceWrapper.tsx
        cat << 'EOF' > resources/scripts/components/dashboard/account/forms/AppearanceWrapper.tsx
import React, { useState, useEffect, ChangeEvent } from 'react';
import { useStoreState } from 'easy-peasy';
import { ApplicationStore } from '@/state';
import { useTranslation } from 'react-i18next';
import TitledGreyBox from '@/components/elements/TitledGreyBox';
import Switch from '@/components/elements/Switch';
import Select from '@/components/elements/Select';
import updateAccountLanguage from '@/api/account/updateAccountLanguage';
import { Button } from '@/components/elements/button/index';
import { DesktopComputerIcon, EyeIcon, MoonIcon, SunIcon } from '@heroicons/react/outline'; 

const AppearanceWrapper = () => {
    const { i18n } = useTranslation('arix/account');
    const [selectedLanguage, setSelectedLanguage] = useState(i18n.language); 

    const {
        modeToggler,
        defaultMode,
        langSwitch,
        languageOptions: languages,
    } = useStoreState((state: ApplicationStore) => state.settings.data!.arix.advanced); 

    const [theme, setTheme] = useState(() => localStorage.getItem('theme') || defaultMode || 'dark');
    const [isCompact, setIsCompact] = useState(() => localStorage.getItem('compactMode') === 'true');
    const [isPrivacyMode, setIsPrivacyMode] = useState(() => localStorage.getItem('privacyMode') === 'true');
    const [panelSounds, setPanelSounds] = useState(() => localStorage.getItem('panelSounds') === 'true');
    const [animations, setAnimations] = useState(() => localStorage.getItem('animations') === 'true'); 

    useEffect(() => {
        localStorage.setItem('theme', theme);
        document.body.classList.remove('lightmode', 'darkmode', 'oled', 'auto');
        if (theme === 'light') {
            document.body.classList.add('lightmode');
        } else if (theme === 'oled') {
            document.body.classList.add('oled');
        } else if (theme === 'auto') {
            document.body.classList.add('auto');
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            document.body.classList.toggle('lightmode', !prefersDark);
        }
    }, [theme]); 

    useEffect(() => {
        localStorage.setItem('compactMode', String(isCompact));
        document.body.classList.toggle('compact', isCompact);
    }, [isCompact]); 

    useEffect(() => {
        localStorage.setItem('privacyMode', String(isPrivacyMode));
        document.body.classList.toggle('privacy', isPrivacyMode);
    }, [isPrivacyMode]); 

    useEffect(() => {
        localStorage.setItem('panelSounds', String(panelSounds));
    }, [panelSounds]); 

    useEffect(() => {
        localStorage.setItem('animations', String(animations));
        document.body.classList.toggle('animationsDisabled', animations);
    }, [animations]); 

    const handleLanguageChange = (event: ChangeEvent<HTMLSelectElement>) => {
        const newLanguage = event.target.value; 

        updateAccountLanguage(newLanguage).then(() => {
            i18n.changeLanguage(newLanguage);
            setSelectedLanguage(newLanguage);
        });
    }; 

    useEffect(() => {
        setSelectedLanguage(i18n.language || 'en');
    }, [i18n.language]); 

    const ToggleRow = ({
        label,
        description,
        offLabel,
        onLabel,
        value,
        onToggle,
        name,
    }: {
        label: React.ReactNode;
        description: string;
        offLabel?: string;
        onLabel?: string;
        value: boolean;
        onToggle: (checked: boolean) => void;
        name: string;
    }) => (
        <div className={'flex justify-between items-center'}>
            <div>
                <p className={'text-gray-100 mb-1'}>{label}</p>
                <p className='text-sm text-gray-300'>{description}</p>
            </div>
            <div className={'flex gap-x-2 items-center'}>
                <span className={'text-sm text-gray-300'}>{offLabel ?? 'Off'}</span>
                <Switch name={name} onChange={() => onToggle(!value)} defaultChecked={value} />
                <span className={'text-sm text-gray-300'}>{onLabel ?? 'On'}</span>
            </div>
        </div>
    ); 

    return (
        <TitledGreyBox title={'Appearance'}>
            <div className='space-y-5'>
                {langSwitch && languages.length > 1 && (
                    <div className={'flex justify-between items-center'}>
                        <div className='flex-1'>
                            <p className={'text-gray-100 mb-1'}>Panel Language</p>
                            <p className='text-sm text-gray-300'>Use the panel in different languages</p>
                        </div>
                        <Select
                            value={selectedLanguage}
                            className={'!w-auto min-w-40 !pr-10'}
                            onChange={handleLanguageChange}
                        >
                            {languages.map((lang: { key: string; name: string }) => (
                                <option key={lang.key} value={lang.key}>
                                    {lang.name}
                                </option>
                            ))}
                        </Select>
                    </div>
                )}
                {modeToggler && (
                    <div className={'flex justify-between items-center'}>
                        <div className='flex-1'>
                            <p className={'text-gray-100 mb-1'}>Light/Dark Mode</p>
                            <p className='text-sm text-gray-300'>Choose the style that suits you best</p>
                        </div>
                        <Button.Text
                            className={`flex gap-1 !rounded-r-none min-w-20 ${theme === 'light' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('light')}
                        >
                            <SunIcon className='w-5' />
                            Light
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-none min-w-20 ${
                                theme === 'darkmode' ? '!bg-gray-500' : ''
                            }`}
                            onClick={() => setTheme('darkmode')}
                        >
                            <MoonIcon className='w-5' />
                            Dark
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-none min-w-20 ${theme === 'oled' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('oled')}
                        >
                            <EyeIcon className='w-5' />
                            Oled
                        </Button.Text>
                        <Button.Text
                            className={`flex gap-1 !rounded-l-none min-w-20 ${theme === 'auto' ? '!bg-gray-500' : ''}`}
                            onClick={() => setTheme('auto')}
                        >
                            <DesktopComputerIcon className='w-5' />
                            Auto
                        </Button.Text>
                    </div>
                )}
                <ToggleRow
                    label={'Display Mode'}
                    description={'Toggle between normal and compact display modes'}
                    value={isCompact}
                    onToggle={setIsCompact}
                    onLabel={'Compact'}
                    offLabel={'Normal'}
                    name={'compact'}
                />
                <ToggleRow
                    label={'Panel Sounds'}
                    description={'Play a sound at crucial moments in the panel'}
                    value={panelSounds}
                    onToggle={setPanelSounds}
                    name={'panel-sounds'}
                />
                <ToggleRow
                    label={'Privacy Mode'}
                    description={'Hide sensitive information in the panel'}
                    value={isPrivacyMode}
                    onToggle={setIsPrivacyMode}
                    name={'privacy'}
                />
                <ToggleRow
                    label={'Animations'}
                    description={'Enable or disable animations in the panel'}
                    value={animations}
                    onToggle={setAnimations}
                    name={'animations'}
                />
            </div>
        </TitledGreyBox>
    );
}; 

export default AppearanceWrapper; 
EOF
        success "AppearanceWrapper.tsx Replaced!"
        info "Compiling panel... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!

        # 4. RegisterController.php
        info "Fixing RegisterController.php..."
        rm -f app/Http/Controllers/Auth/RegisterController.php
        cat << 'EOF' > app/Http/Controllers/Auth/RegisterController.php
<?php 

namespace Pterodactyl\Http\Controllers\Auth; 

use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\ModelNotFoundException; 

class RegisterController extends AbstractRegisterController
{
    /**
     * Handle all incoming requests for the authentication routes and render the
     * base authentication view component. React will take over at this point and
     * turn the register area into an SPA.
     */
    public function index(): View
    {
        return view('templates/auth.core');
    } 

    /**
     * Handle a register request to the application.
     *
     * @throws \Pterodactyl\Exceptions\DisplayException
     * @throws \Illuminate\Validation\ValidationException
     */
    public function register(Request $request): JsonResponse
    {
        if ($this->hasTooManyLoginAttempts($request)) {
            $this->fireLockoutEvent($request);
            $this->sendLockoutResponse($request);
        } 

        try {
            $user = User::where('email', $request->input('email'))->orWhere('username', $request->input('username'))->first(); 

            if ($user) {
                return response()->json(['error' => 'The email or username is already taken.'], 400);
            }
        } catch (ModelNotFoundException) {
            $this->sendFailedRegisterResponse($request);
        } 

        return $this->sendRegisterResponse($request);
    }
}
EOF
        success "RegisterController.php Replaced!"
        info "Compiling panel final step... (Please wait)"
        ( yarn build > /dev/null 2>&1 ) & spinner $!
        
        # ==========================================
        # COMPLETION
        # ==========================================
        echo ""
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "    🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉    "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${CYAN} Your Pterodactyl Panel has been updated with Arix v${LICENSE_VERSION} (${LICENSE_TYPE}).${NC}"
        echo -e "${WHITE} If you encounter any issues, try clearing your browser cache.${NC}\n" 
        echo ""
        read -p "Press Enter to return to main menu..."
        return 0
    fi
}

# ==========================================
# ADDON INSTALLER FUNCTIONS
# ==========================================
addon_names=(
    "autobackups.blueprint"
    "minecraftplayermanager.blueprint"
    "modrinthbrowser.blueprint"
    "motdmaker.blueprint"
    "resourcemanager.blueprint"
    "sagaautosuspension.blueprint"
    "sagaminecraftmodpackinstaller.blueprint"
    "servericonimporter.blueprint"
    "serverpropsmanager.blueprint"
    "serversplitter.blueprint"
    "snowflakes.blueprint"
    "stats.blueprint"
    "subdomainmanager.blueprint"
    "versionchanger.blueprint"
)

is_addon_installed() {
    if [[ -d "/var/www/pterodactyl/storage/extensions/${1%.blueprint}" ]]; then
        return 0
    else
        return 1
    fi
}

run_addon_blueprint() {
    local NAME="$1"
    local ACT="$2"
    cd /var/www/pterodactyl || exit 1
    if [[ "$ACT" == "install" ]]; then
        echo -e "${GREEN}📥 Installing ${NAME%.blueprint}...${NC}"
        wget -q "$ADDON_URL/$NAME" -O "$NAME" || true
        if [[ -s "$NAME" ]]; then
            yes | blueprint -i "$NAME" || true
            rm -f "$NAME"
        fi
    else
        echo -e "${RED}🗑️ Removing ${NAME%.blueprint}...${NC}"
        yes | blueprint -r "${NAME%.blueprint}" || true
    fi
}

addon_installer_menu() {
    if ! command -v blueprint >/dev/null 2>&1; then
        echo ""
        error "Blueprint Framework is NOT installed!"
        warning "First install Blueprint Framework before installing addons."
        sleep 3
        return 0
    fi

    while true; do
        clear
        echo -e "${CYAN} ╔══════════════════════════════════════════════════════════╗${NC}"
        printf " ${CYAN}║${WHITE}%-58s${CYAN}║${NC}\n" "Theme Addon Installer (Blueprint)"
        echo -e "${CYAN} ╚══════════════════════════════════════════════════════════╝${NC}"
        local count=0
        for i in "${!addon_names[@]}"; do
            num=$((i + 1))
            clean_name="${addon_names[$i]%.blueprint}"
            
            if is_addon_installed "$clean_name"; then
                status="${GREEN}●${NC}"
            else
                status="${RED}○${NC}"
            fi
            display_name="${clean_name:0:24}"
            
            printf "  ${GREEN}%2d${NC}) %-24s %b " "$num" "$display_name" "$status"
            
            count=$((count + 1))
            if [[ $((count % 2)) -eq 0 ]]; then
                echo ""
            fi
        done
        
        if [[ $((count % 2)) -ne 0 ]]; then
            echo ""
        fi

        echo -e "${CYAN} ──────────────────────────────────────────────────────────${NC}"
        echo -e " ${WHITE}Commands:${NC}"
        echo -e " ${YELLOW}1, 1,2, 1 2 3${NC} : Install specific addon(s)"
        echo -e " ${YELLOW}all${NC}           : Install ALL addons"
        echo -e " ${YELLOW}r 1, r 1,2${NC}    : Remove specific addon(s) (or 'r all')"
        echo -e " ${RED}0${NC}             : Go Back"
        echo -e "${CYAN} ──────────────────────────────────────────────────────────${NC}"

        read -p " 👉 Select Action: " choice
        
        choice=${choice//,/ }
        choice_lower=${choice,,}

        if [[ "$choice_lower" == "0" ]]; then
            return 0
        fi

        local action_type="install"
        local targets="$choice_lower"

        if [[ "$choice_lower" == r\ * ]]; then
            action_type="remove"
            targets="${choice_lower:2}"
        fi

        local selected_addons=()
        if [[ "$targets" == "all" ]]; then
            for i in "${!addon_names[@]}"; do
                selected_addons+=("$i")
            done
        else
            for val in $targets; do
                if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -ge 1 ]] && [[ "$val" -le "${#addon_names[@]}" ]]; then
                    selected_addons+=($((val-1)))
                else
                    if [[ -n "$val" ]]; then
                        echo -e "${RED}Invalid option ignored: $val${NC}"
                    fi
                fi
            done
        fi

        if [[ ${#selected_addons[@]} -eq 0 ]]; then
            continue
        fi

        if [[ "$action_type" == "install" ]]; then
            # 1. Install resourcemanager FIRST if selected
            for idx in "${selected_addons[@]}"; do
                if [[ "${addon_names[$idx]}" == "resourcemanager.blueprint" ]]; then
                    run_addon_blueprint "resourcemanager.blueprint" "install"
                fi
            done
            
            # 2. Install the rest sequentially
            for idx in "${selected_addons[@]}"; do
                if [[ "${addon_names[$idx]}" != "resourcemanager.blueprint" ]]; then
                    run_addon_blueprint "${addon_names[$idx]}" "install"
                fi
            done
        else
            # 3. Removal logic
            for idx in "${selected_addons[@]}"; do
                run_addon_blueprint "${addon_names[$idx]}" "remove"
            done
        fi
        
        echo ""
        read -p "Done. Press Enter to return..."
    done
}


# ==========================================
# MAIN MENU LOOP
# ==========================================
while true; do
    show_banner
    echo -e "${WHITE}Please select what you want to do:${NC}\n"
    echo -e "${CYAN}  [ 1 ] ${WHITE}Theme Installer"
    echo -e "${CYAN}  [ 2 ] ${WHITE}Theme Addon Installer"
    echo -e "${RED}  [ 0 ] ${WHITE}Exit${NC}\n"
    
    echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
    read main_opt
    echo -ne "${NC}"
    
    case $main_opt in
        1) 
            theme_installer_menu 
            if [ -n "$ACTION" ]; then
                execute_theme_action
            fi
            ;;
        2) 
            addon_installer_menu 
            ;;
        0) 
            echo -e "\n${MAGENTA} Bye!${NC}"
            exit 0 
            ;;
        *) 
            warning "Invalid selection. Try again."
            sleep 1 
            ;;
    esac
done
