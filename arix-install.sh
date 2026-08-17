#!/bin/bash
# ==========================================
# 🔐 BASIC PROTECTION & SETUP
# ==========================================
[[ $EUID -ne 0 ]] && echo -e "\033[1;31mRun as root!\033[0m" && exit 1

trap 'echo -e "\n\033[1;31m[!] Force exit detected.\033[0m"; exit 1' SIGINT

# ==========================================
# 🎨 COLORS & TYPOGRAPHY
# ==========================================
RED='\033[1;31m'; GREEN='\033[1;32m'; BLUE='\033[1;34m'
CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; YELLOW='\033[1;33m'
WHITE='\033[1;37m'; NC='\033[0m'

R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; M="\e[35m"; C="\e[36m"; W="\e[97m"; N="\e[0m"
BR="\e[1;31m"; BG="\e[1;32m"; BY="\e[1;33m"; BM="\e[1;35m"; BC="\e[1;36m"; BW="\e[1;97m"

# ==========================================
# 🛡️ SECURITY & OBFUSCATION (HIDDEN URLs)
# ==========================================
_dec() { echo "$1" | base64 -d; }

API_URL=$(_dec "aHR0cDovLzc4LjE1NC4xMDMuMjc6MTM5MTUvYXBpL3ZlcmlmeQ==")
ADDON_URL=$(_dec "aHR0cHM6Ly9naXRodWIuY29tL25vYml0YTMyOS9Ob2JpdGEtQ2xvdWQvcmF3L3JlZnMvaGVhZHMvbWFpbi90aGFtZS9FeHRlbnNpb24=")

ACTION=""
LICENSE_TYPE=""
LICENSE_VERSION=""
DOWNLOAD_URL=""
selected_indices=()

# ==========================================
# 🧠 BLUEPRINT ADDON LIST 
# ==========================================
ADDON_NAMES=(
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

# ==========================================
# 🔍 CUSTOM LOGGERS & ANIMATIONS
# ==========================================
info() { echo -e "${BLUE}[ℹ] ${WHITE}$1${NC}"; }
success() { echo -e "${GREEN}[✔] ${WHITE}$1${NC}"; }
warning() { echo -e "${YELLOW}[⚠] ${WHITE}$1${NC}"; }
error() { echo -e "${RED}[✖] ${WHITE}$1${NC}"; }
step() { echo -e "\n${MAGENTA}➤ ${CYAN}Step $1: ${WHITE}$2${NC}"; } 

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
    printf "\r\033[K"
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

show_banner() {
    clear
    echo -e "${MAGENTA}"
    echo '   █████╗ ██████╗ ██╗██╗  ██╗'
    echo '  ██╔══██╗██╔══██╗██║╚██╗██╔╝'
    echo '  ███████║██████╔╝██║ ╚███╔╝ '
    echo '  ██╔══██║██╔══██╗██║ ██╔██╗ '
    echo '  ██║  ██║██║  ██║██║██╔╝ ██╗'
    echo '  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
    typewriter "         Advanced Pterodactyl Installer"
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
} 

# ==========================================
# 📦 ARIX THEME FUNCTIONS
# ==========================================
check_dependencies() {
    info "Verifying Node.js and Yarn requirements..."
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
    [[ -z "$MESSAGE" ]] && MESSAGE="Invalid response from the licensing server."

    if [ "$SUCCESS" != "true" ]; then
        echo ""
        error "Authentication Denied: $MESSAGE"
        exit 1
    else
        echo ""
        success "License Verified! Authorization Granted."
        sleep 1.5
    fi
} 

apply_permissions_function() {
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
}

apply_fixes_function() {
    info "Injecting Arix 2.1.0 Auto Fixes..."
    
    info "Replacing RouterElements.tsx..."
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

import blueprintRoutes from '@blueprint/extends/routers/routes';
import { HiOutlineAdjustments, HiAdjustments } from 'react-icons/hi';
import { LuSlidersVertical } from 'react-icons/lu';
import { RiSoundModuleLine, RiSoundModuleFill } from 'react-icons/ri'; 

import { 
    FaEdit, FaGlobe, FaCogs, FaCodeBranch, FaBoxOpen, FaPlug, 
    FaMap, FaUsers, FaFileImport, FaPuzzlePiece, FaLayerGroup, 
    FaCube, FaRocket, FaBolt, FaTerminal, FaArchive, FaDatabase, FaCalendarAlt 
} from 'react-icons/fa';

const ICON_MAP: Record<string, number> = { heroicons: 0, heroiconsFilled: 1, lucide: 2, remixicon: 3, remixiconFilled: 4 };

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

const getAdjustedPath = (path: string, isDashboardDisabled: boolean) => path === '/console' && isDashboardDisabled ? '/' : path; 

const Link = (props: LinkItem) => {
    const { t } = useTranslation('arix/navigation');
    const { nestId, eggId, tier } = useServerIds();
    const tierVisibility = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.advanced?.tierVisibility ?? 'show'); 

    const permissions = (props.permission ?? []).filter((permission) => permission && permission.trim().length > 0);
    const hasPermissions = permissions.length > 0; 
    const hasNestRestrictions = Array.isArray(props.nests) && props.nests.length > 0;
    const hasEggRestrictions = Array.isArray(props.eggs) && props.eggs.length > 0;
    const hasTierRestrictions = Array.isArray(props.tier) && props.tier.length > 0; 
    const nestMatches = hasNestRestrictions && typeof nestId === 'number' && props.nests?.includes(nestId) === true;
    const eggMatches = hasEggRestrictions && typeof eggId === 'number' && props.eggs?.includes(eggId) === true;
    const tierMatches = hasTierRestrictions && tier !== null && tier !== undefined && props.tier?.includes(tier) === true; 
    const hasRestrictions = hasNestRestrictions || hasEggRestrictions || hasTierRestrictions; 
    const showStar = hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'show';
    const shouldHide = hasTierRestrictions && tier !== null && tier !== undefined && !tierMatches && tierVisibility === 'hidden'; 

    const buildPath = usePathBuilder(); 
    if (hasRestrictions && !nestMatches && !eggMatches && shouldHide) return null;

    const starIcon = showStar ? <StarIcon className='w-3 text-yellow-500' /> : null; 
    const linkContent = (
        <>
            <div className='routers_link_icon'><Icon name={props.icon} size='1.25rem' /></div>
            <span className='routers_link_title'>{t(props.name)}</span>
            {starIcon}
        </>
    ); 

    const inner = props.url.includes('http') ? (
        <div className='relative'>
            <a key={props.name} href={props.url} target='_blank' rel='noreferrer' className='routers_link'>{linkContent}</a>
        </div>
    ) : (
        <div className='relative'>
            <NavLink key={props.name} to={buildPath(props.url, true)} exact={props.url === '/'} className='routers_link'>{linkContent}</NavLink>
        </div>
    ); 

    return hasPermissions ? <Can action={permissions} matchAny>{inner}</Can> : inner;
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

    if (hasRestrictions && !nestMatches && !eggMatches) return null;

    return hasPermissions ? (
        <Can action={permissions} matchAny>
            <div key={props.name} className='routers_category-wrapper'>
                <span className='routers_category'>{t(props.name)}</span>
                <div className='routers_links'>
                    {props.links.map((link) => <Link key={link.name} {...link} />)}
                </div>
            </div>
        </Can>
    ) : (
        <div className='routers_category-wrapper'>
            <span className='routers_category'>{t(props.name)}</span>
            <div className='routers_links'>
                {props.links.map((link) => <Link key={link.name} {...link} />)}
            </div>
        </div>
    );
}; 

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
                } catch (e) { newEggs[id] = ['-1']; }
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

const getRouteKey = (route: any) => `${route.name || ''} ${route.path || ''} ${route.identifier || ''}`.toLowerCase();

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
        <FaPuzzlePiece size="1.25rem" />, <FaLayerGroup size="1.25rem" />, <FaCube size="1.25rem" />, 
        <FaRocket size="1.25rem" />, <FaBolt size="1.25rem" />, <FaTerminal size="1.25rem" />
    ];
    let hash = 0;
    for (let i = 0; i < key.length; i++) { hash = key.charCodeAt(i) + ((hash << 5) - hash); }
    return genericIcons[Math.abs(hash) % genericIcons.length];
}; 

const BlueprintLink = ({ route }: { route: any }) => {
    const buildPath = usePathBuilder();
    const iconType = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.icon ?? 'heroicons');
    const { t } = useTranslation('arix/navigation');
    
    const inner = (
        <NavLink to={buildPath(route.path, true)} exact={route.exact} className='routers_link'>
            <div className='routers_link_icon'>{renderBlueprintIcon(route, iconType)}</div>
            <span className='routers_link_title'>{t(route.name) || route.name}</span>
        </NavLink>
    ); 
    return route.permission ? <Can action={route.permission} matchAny>{inner}</Can> : inner;
};

export const Navigation = () => {
    const links = useStoreState((state: ApplicationStore) => state.settings.data?.arix?.links ?? {});
    const blueprintServerRoutes = useBlueprintServerRoutes(); 

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
                return 99; 
            }; 
            const rankA = getRank(keyA);
            const rankB = getRank(keyB); 
            if (rankA !== rankB) return rankA - rankB;
            return keyA.localeCompare(keyB);
        });
    }, [blueprintServerRoutes]);

    return (
        <React.Fragment>
            {Object.values(links).map((category, index) => <Category key={index} {...category} />)} 
            {sortedBlueprintRoutes.length > 0 && (
                <div className='routers_category-wrapper'>
                    <span className='routers_category'>Extensions</span>
                    <div className='routers_links'>
                        {sortedBlueprintRoutes.map((route) => <BlueprintLink key={route.path} route={route} />)}
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
        const link = Object.values(links ?? {}).flatMap((category) => category.links).find((link) => link.url === routePath); 
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
                            <Spinner.Suspense><Component /></Spinner.Suspense>
                        </PermissionRoute>
                    );
                })} 
                {blueprintServerRoutes.map(({ path, permission, component: Component }) => (
                    <PermissionRoute key={path} permission={permission} path={buildPath(path)} exact>
                        <Spinner.Suspense><Component /></Spinner.Suspense>
                    </PermissionRoute>
                ))} 
                <Route path={'*'} component={NotFound} />
            </Switch>
        </TransitionRouter>
    );
};
EOF
    success "RouterElements.tsx patched successfully."

    info "Replacing DashboardRouter.tsx..."
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
import BeforeSubNavigation from '@blueprint/components/Navigation/SubNavigation/BeforeSubNavigation';
import AdditionalAccountItems from '@blueprint/components/Navigation/SubNavigation/AdditionalAccountItems';
import AfterSubNavigation from '@blueprint/components/Navigation/SubNavigation/AfterSubNavigation';
import blueprintRoutes from '@blueprint/extends/routers/routes';

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
                            <div className={'w-10 h-10 bg-arix/30 rounded-component !border-none flex items-center justify-center text-arix'}>
                                <UserIcon className={'w-6'} />
                            </div>
                            <p className={'text-lg font-medium text-gray-300'}>{t('account-settings')}</p>
                        </div>
                        <div className='flex items-center gap-x-8'> 
                            <BeforeSubNavigation /> 
                            <NavLink to={'/account'} className={'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'} activeClassName={'!border-arix text-gray-100'} exact><CogIcon className={'w-5'} />{t('general')}</NavLink>
                            <NavLink to={'/account/security'} className={'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'} activeClassName={'!border-arix text-gray-100'}><LockClosedIcon className={'w-5'} />{t('security')}</NavLink>
                            <NavLink to={'/account/ssh-keys'} className={'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'} activeClassName={'!border-arix text-gray-100'}><KeyIcon className={'w-5'} />{t('ssh-keys')}</NavLink>
                            <NavLink to={'/account/api-keys'} className={'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'} activeClassName={'!border-arix text-gray-100'}><CodeIcon className={'w-5'} />{t('api-keys')}</NavLink>
                            <NavLink to={'/account/activity'} className={'border-b border-transparent py-2 flex items-center gap-1 hover:text-gray-100 duration-300'} activeClassName={'!border-arix text-gray-100'}><EyeIcon className={'w-5'} />{t('activity')}</NavLink> 
                            <AdditionalAccountItems />
                            <AfterSubNavigation /> 
                        </div>
                    </ContentContainer>
                </div>
            )} 

            <TransitionRouter>
                <React.Suspense fallback={<Spinner centered />}>
                    <Switch location={location}>
                        <Route path={'/'} exact><DashboardContainer /></Route>
                        {routes.account.map(({ path, component: Component }) => <Route key={path} path={`/account/${path}`.replace('//', '/')} exact><Component /></Route>)} 
                        {(blueprintRoutes.account || []).map(({ path, component: Component }) => <Route key={path} path={`/account/${path}`.replace('//', '/')} exact><Component /></Route>)} 
                        <Route path={'*'}><NotFound /></Route>
                    </Switch>
                </React.Suspense>
            </TransitionRouter>
        </LayoutWrapper>
    );
};
EOF
    success "DashboardRouter.tsx patched successfully."

    info "Replacing AppearanceWrapper.tsx..."
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
    const { modeToggler, defaultMode, langSwitch, languageOptions: languages } = useStoreState((state: ApplicationStore) => state.settings.data!.arix.advanced); 

    const [theme, setTheme] = useState(() => localStorage.getItem('theme') || defaultMode || 'dark');
    const [isCompact, setIsCompact] = useState(() => localStorage.getItem('compactMode') === 'true');
    const [isPrivacyMode, setIsPrivacyMode] = useState(() => localStorage.getItem('privacyMode') === 'true');
    const [panelSounds, setPanelSounds] = useState(() => localStorage.getItem('panelSounds') === 'true');
    const [animations, setAnimations] = useState(() => localStorage.getItem('animations') === 'true'); 

    useEffect(() => {
        localStorage.setItem('theme', theme);
        document.body.classList.remove('lightmode', 'darkmode', 'oled', 'auto');
        if (theme === 'light') { document.body.classList.add('lightmode'); }
        else if (theme === 'oled') { document.body.classList.add('oled'); }
        else if (theme === 'auto') {
            document.body.classList.add('auto');
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            document.body.classList.toggle('lightmode', !prefersDark);
        }
    }, [theme]); 

    useEffect(() => { localStorage.setItem('compactMode', String(isCompact)); document.body.classList.toggle('compact', isCompact); }, [isCompact]); 
    useEffect(() => { localStorage.setItem('privacyMode', String(isPrivacyMode)); document.body.classList.toggle('privacy', isPrivacyMode); }, [isPrivacyMode]); 
    useEffect(() => { localStorage.setItem('panelSounds', String(panelSounds)); }, [panelSounds]); 
    useEffect(() => { localStorage.setItem('animations', String(animations)); document.body.classList.toggle('animationsDisabled', animations); }, [animations]); 

    const handleLanguageChange = (event: ChangeEvent<HTMLSelectElement>) => {
        const newLanguage = event.target.value; 
        updateAccountLanguage(newLanguage).then(() => {
            i18n.changeLanguage(newLanguage);
            setSelectedLanguage(newLanguage);
        });
    }; 
    useEffect(() => { setSelectedLanguage(i18n.language || 'en'); }, [i18n.language]); 

    const ToggleRow = ({ label, description, offLabel, onLabel, value, onToggle, name }: any) => (
        <div className={'flex justify-between items-center'}>
            <div><p className={'text-gray-100 mb-1'}>{label}</p><p className='text-sm text-gray-300'>{description}</p></div>
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
                        <div className='flex-1'><p className={'text-gray-100 mb-1'}>Panel Language</p><p className='text-sm text-gray-300'>Use the panel in different languages</p></div>
                        <Select value={selectedLanguage} className={'!w-auto min-w-40 !pr-10'} onChange={handleLanguageChange}>
                            {languages.map((lang: { key: string; name: string }) => <option key={lang.key} value={lang.key}>{lang.name}</option>)}
                        </Select>
                    </div>
                )}
                {modeToggler && (
                    <div className={'flex justify-between items-center'}>
                        <div className='flex-1'><p className={'text-gray-100 mb-1'}>Light/Dark Mode</p><p className='text-sm text-gray-300'>Choose the style that suits you best</p></div>
                        <Button.Text className={`flex gap-1 !rounded-r-none min-w-20 ${theme === 'light' ? '!bg-gray-500' : ''}`} onClick={() => setTheme('light')}><SunIcon className='w-5' /> Light</Button.Text>
                        <Button.Text className={`flex gap-1 !rounded-none min-w-20 ${theme === 'darkmode' ? '!bg-gray-500' : ''}`} onClick={() => setTheme('darkmode')}><MoonIcon className='w-5' /> Dark</Button.Text>
                        <Button.Text className={`flex gap-1 !rounded-none min-w-20 ${theme === 'oled' ? '!bg-gray-500' : ''}`} onClick={() => setTheme('oled')}><EyeIcon className='w-5' /> Oled</Button.Text>
                        <Button.Text className={`flex gap-1 !rounded-l-none min-w-20 ${theme === 'auto' ? '!bg-gray-500' : ''}`} onClick={() => setTheme('auto')}><DesktopComputerIcon className='w-5' /> Auto</Button.Text>
                    </div>
                )}
                <ToggleRow label={'Display Mode'} description={'Toggle between normal and compact display modes'} value={isCompact} onToggle={setIsCompact} onLabel={'Compact'} offLabel={'Normal'} name={'compact'} />
                <ToggleRow label={'Panel Sounds'} description={'Play a sound at crucial moments in the panel'} value={panelSounds} onToggle={setPanelSounds} name={'panel-sounds'} />
                <ToggleRow label={'Privacy Mode'} description={'Hide sensitive information in the panel'} value={isPrivacyMode} onToggle={setIsPrivacyMode} name={'privacy'} />
                <ToggleRow label={'Animations'} description={'Enable or disable animations in the panel'} value={animations} onToggle={setAnimations} name={'animations'} />
            </div>
        </TitledGreyBox>
    );
}; 
export default AppearanceWrapper; 
EOF
    success "AppearanceWrapper.tsx patched successfully."

    info "Patching RegisterController.php..."
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
    public function index(): View { return view('templates/auth.core'); } 
    public function register(Request $request): JsonResponse
    {
        if ($this->hasTooManyLoginAttempts($request)) {
            $this->fireLockoutEvent($request);
            $this->sendLockoutResponse($request);
        } 
        try {
            $user = User::where('email', $request->input('email'))->orWhere('username', $request->input('username'))->first(); 
            if ($user) { return response()->json(['error' => 'The email or username is already taken.'], 400); }
        } catch (ModelNotFoundException) { $this->sendFailedRegisterResponse($request); } 
        return $this->sendRegisterResponse($request);
    }
}
EOF
    success "RegisterController.php patched successfully."

    info "Building Panel Assets with Fixes (Takes 2-5 minutes)..."
    (
        yarn add xterm-addon-unicode11 > /dev/null 2>&1
        yarn build > /dev/null 2>&1
    ) & spinner $!
    success "Panel compiled successfully!"
}

# ==========================================
# 🛠️ ARIX THEME MENUS
# ==========================================
menu_action_210() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Action for ${GREEN}Arix v2.1.0 ($LICENSE_TYPE)${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Install + Auto Fix"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Uninstall"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Fixes Issues ${YELLOW}(For already installed panels)${NC}"
        echo -e "${CYAN}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read action_choice
        case $action_choice in
            1) ACTION="install"; return 0 ;;
            2) ACTION="uninstall"; return 0 ;;
            3) ACTION="fix"; return 0 ;;
            0) ACTION=""; return 0 ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

menu_action_208() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Action for ${GREEN}Arix v2.0.8 ($LICENSE_TYPE)${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Install"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Uninstall"
        echo -e "${CYAN}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read action_choice
        case $action_choice in
            1) ACTION="install"; return 0 ;;
            2) ACTION="uninstall"; return 0 ;;
            0) ACTION=""; return 0 ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

menu_edition_210() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.1.0${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_210
        case $choice_210 in
            1) 
                LICENSE_TYPE="non-blueprint"; LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL=$(_dec "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3NkZ2FtZXI4MjYzLXNrZXRjaC9wdGVyb2RhY3R5bF9leHRlbnRpb24xL21haW4vc2QvdjIxMC9wdGVyb2RhY3R5bC56aXA=")
                menu_action_210
                [[ -n "$ACTION" ]] && return 0
                ;;
            2) 
                LICENSE_TYPE="blueprint"; LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL=$(_dec "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3NkZ2FtZXI4MjYzLXNrZXRjaC9wdGVyb2RhY3R5bF9leHRlbnRpb24xL21haW4vcHRlcm9kYWN0eWwuemlw")
                menu_action_210
                [[ -n "$ACTION" ]] && return 0
                ;;
            0) return 0 ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

menu_edition_208() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.0.8${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_208
        case $choice_208 in
            1) 
                LICENSE_TYPE="non-blueprint"; LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL=$(_dec "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3NkZ2FtZXI4MjYzLXNrZXRjaC9wdGVyb2RhY3R5bF9leHRlbnRpb24xL21haW4vc2QvdjIwOC9wdGVyb2RhY3R5bC56aXA=")
                menu_action_208
                [[ -n "$ACTION" ]] && return 0
                ;;
            2) 
                LICENSE_TYPE="blueprint"; LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL=$(_dec "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3NkZ2FtZXI4MjYzLXNrZXRjaC9wdGVyb2RhY3R5bF9leHRlbnRpb24xL21haW4vc2QvYXYxcHRlcm9kYWN0eWwuemlw")
                menu_action_208
                [[ -n "$ACTION" ]] && return 0
                ;;
            0) return 0 ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

execute_theme_action() {
    if [ "$ACTION" == "uninstall" ]; then
        show_banner
        [[ ! -d "/var/www/pterodactyl" ]] && error "Pterodactyl not found!" && exit 1
        cd /var/www/pterodactyl
        step "1/1" "Uninstalling Arix Theme..."
        php artisan arix uninstall
        echo -e "\n${GREEN} 🎉 UNINSTALLATION COMPLETED SUCCESSFULLY! 🎉 ${NC}\n"
        exit 0
    fi

    if [ "$ACTION" == "fix" ]; then
        show_banner; check_dependencies
        [[ ! -d "/var/www/pterodactyl" ]] && error "Pterodactyl not found!" && exit 1
        cd /var/www/pterodactyl
        step "1/1" "Applying Auto Fixes & Compiling Panel..."
        apply_fixes_function
        apply_permissions_function
        echo -e "\n${GREEN} 🎉 FIXES APPLIED SUCCESSFULLY! 🎉 ${NC}\n"
        exit 0
    fi

    if [ "$ACTION" == "install" ]; then
        show_banner
        verify_license "$LICENSE_TYPE" "$LICENSE_VERSION"
        show_banner; check_dependencies 

        [[ ! -d "/var/www/pterodactyl" ]] && error "Pterodactyl not found!" && exit 1
        cd /var/www/pterodactyl 

        step "1/4" "Downloading Arix Theme Assets..."
        (curl -sL -o pterodactyl.zip "$DOWNLOAD_URL") & spinner $!
        success "Downloaded successfully." 

        step "2/4" "Extracting Core Files..."
        ( unzip -o pterodactyl.zip >/dev/null 2>&1; [[ -d "pterodactyl" ]] && cp -rf pterodactyl/* ./ && rm -rf pterodactyl; rm pterodactyl.zip ) & spinner $!
        success "Files extracted." 

        step "3/4" "Injecting Modules..."
        if [ "$LICENSE_VERSION" == "2.1.0" ]; then
            cat << 'EOF' > app/Console/Commands/Arix.php
<?php 
namespace Pterodactyl\Console\Commands; 
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File; 
class Arix extends Command
{
    protected $signature = "arix {action?}";
    public function handle() {
        $action = $this->argument("action");
        if ($action === "install") {
            $this->info("Installing Arix Theme...");
            $versions = File::directories("./arix");
            if (empty($versions)) { $this->info("No versions found."); return; }
            $version = basename($versions[count($versions) - 1]);
            exec("rsync -a arix/{$version}/ ./"); 
            $this->command("php artisan migrate --force");
            $this->command("yarn add react-email-editor react-colorful recharts@^2.15.4 ua-parser-js cronstrue react-day-picker jszip react-turnstile @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @types/md5 md5 react-icons@5.4.0 markdown-to-jsx@7.7.10 i18next-browser-languagedetector@7.2.1");
            $this->command("php artisan optimize:clear");
            $this->command("php artisan queue:restart");
        } elseif ($action === "uninstall") {
            $this->command("curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv");
            $this->command("chmod -R 755 storage/* bootstrap/cache");
            $this->command("composer install --no-dev --optimize-autoloader");
            $this->command("php artisan optimize:clear");
            $this->command("php artisan migrate --seed --force");
        }
    }
    private function command($cmd) { return exec($cmd); }
}
EOF
            php artisan arix install
        fi
        success "Modules injected!" 

        if [ "$LICENSE_VERSION" == "2.1.0" ]; then
            step "4/4" "Applying Auto Fixes & Compiling Panel (v2.1.0)..."
            apply_fixes_function
        else
            step "4/4" "Compiling Pterodactyl Panel (Production Build)..."
            (yarn add xterm-addon-unicode11 > /dev/null 2>&1; yarn build > /dev/null 2>&1) & spinner $!
            success "Panel compiled successfully!" 
        fi

        apply_permissions_function
        echo -e "\n${GREEN} 🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉 ${NC}\n"
        exit 0
    fi
}

run_theme_installer() {
    while true; do
        show_banner
        typewriter " Welcome to the Arix Theme setup. Select Version:"
        echo ""
        echo -e "${CYAN}  [ 1 ] ${WHITE}Arix v2.1.0 ${GREEN}(Latest)${NC}"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Arix v2.0.8 ${YELLOW}(Legacy)${NC}"
        echo -e "${CYAN}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read main_choice
        
        case $main_choice in
            1) menu_edition_210; [[ -n "$ACTION" ]] && break ;;
            2) menu_edition_208; [[ -n "$ACTION" ]] && break ;;
            0) return 0 ;;
            *) warning "Invalid selection. Try again."; sleep 1 ;;
        esac
    done
    
    execute_theme_action
}

# ==========================================
# 🧩 BLUEPRINT ADDON FUNCTIONS
# ==========================================
check_blueprint_framework() {
    if ! command -v blueprint >/dev/null 2>&1 && [ ! -f "/usr/local/bin/blueprint" ]; then
        echo -e "\n${RED}[✖] First install Blueprint Framework!${NC}"
        echo -e "${YELLOW}The Blueprint Framework must be installed on your panel before installing Addons.${NC}\n"
        read -p "Press Enter to return to the main menu..." dummy
        return 1
    fi
    return 0
}

is_installed() { [[ -d "/var/www/pterodactyl/storage/extensions/${1%.blueprint}" ]] && return 0 || return 1; }
is_selected() { [[ " ${selected_indices[*]} " =~ " $1 " ]] && return 0 || return 1; }
get_title() { echo 'ICAgICAg44CCIOKAjCDigJMgTm9iaXRhLmRldiBDT05UUk9MIEhVQiDigJMg44CCICAgICAg' | base64 -d; }

run_blueprint() {
    local NAME="$1"
    local ACTION="$2"
    cd /var/www/pterodactyl || exit 1
    
    if [[ "$ACTION" == "install" ]]; then
        echo -e "${G}📥 Installing ${NAME%.blueprint}...${N}"
        wget -q "$ADDON_URL/$NAME" -O "$NAME"
        if [[ -s "$NAME" ]]; then
            yes | blueprint -i "$NAME"
            rm -f "$NAME"
        else
            echo -e "${R}Failed to download ${NAME}${N}"
        fi
    else
        echo -e "${R}🗑️ Removing ${NAME%.blueprint}...${N}"
        yes | blueprint -r "${NAME%.blueprint}"
    fi
}

show_addon_menu() {
    clear
    echo -e "${BC} ╔══════════════════════════════════════════════════════════╗${N}"
    printf " ${BC}║${BW}%-58s${BC}║${N}\n" "$(get_title)"
    echo -e "${BC} ╚══════════════════════════════════════════════════════════╝${N}"
    
    local count=0
    for i in "${!ADDON_NAMES[@]}"; do
        num=$((i+1))
        clean_name="${ADDON_NAMES[$i]%.blueprint}"
        
        is_installed "$clean_name" && status="${BG}●${N}" || status="${R}○${N}"
        is_selected "$i" && select_mark="${BY}[+]${N}" || select_mark="   "
        
        display_name="${clean_name:0:22}"
        printf " %b ${BG}%2d${N} %-22s %b " "$select_mark" "$num" "$display_name" "$status"
        
        ((count++))
        [[ $((count % 2)) -eq 0 ]] && echo ""
    done
    [[ $((count % 2)) -ne 0 ]] && echo ""
    
    echo -e "${C} ──────────────────────────────────────────────────────────${N}"
    echo -e " ${BW}SELECTED:${N} ${BY}${#selected_indices[@]}${N} items"
    echo -e " ${BG}[i]${N} Install   ${BR}[r]${N} Remove   ${BM}[a]${N} Select All   ${BC}[c]${N} Clear   ${R}[0]${N} Go Back"
    echo -e " ${Y}Tip: Type 'all' to install everything, or '1,2,3' to select multiple.${N}"
    echo -e "${C} ──────────────────────────────────────────────────────────${N}"
}

run_addon_installer() {
    if ! check_blueprint_framework; then return 0; fi

    selected_indices=()
    while true; do
        show_addon_menu
        read -p " 👉 Select ID(s) or Action: " raw_choice
        
        choice=$(echo "$raw_choice" | tr ',' ' ')
        
        if [[ "${choice,,}" == "all" ]]; then
            selected_indices=()
            for i in "${!ADDON_NAMES[@]}"; do selected_indices+=("$i"); done
            choice="i"
        fi

        case $choice in
            0) break ;;
            c|C) selected_indices=() ;;
            a|A) selected_indices=(); for i in "${!ADDON_NAMES[@]}"; do selected_indices+=("$i"); done ;;
            i|I|r|R)
                if [[ ${#selected_indices[@]} -eq 0 ]]; then echo -e "${R}Nothing selected!${N}"; sleep 1; continue; fi
                
                action_type="install"
                [[ "$choice" =~ [rR] ]] && action_type="remove"
                
                local rm_idx=-1
                for i in "${!ADDON_NAMES[@]}"; do
                    if [[ "${ADDON_NAMES[$i]}" == "resourcemanager.blueprint" ]]; then rm_idx=$i; break; fi
                done
                
                if [[ " ${selected_indices[*]} " =~ " $rm_idx " ]]; then run_blueprint "${ADDON_NAMES[$rm_idx]}" "$action_type"; fi
                for idx in "${selected_indices[@]}"; do
                    if [[ "$idx" != "$rm_idx" ]]; then run_blueprint "${ADDON_NAMES[$idx]}" "$action_type"; fi
                done
                
                selected_indices=()
                echo ""
                read -p "Done. Press Enter to return..." dummy
                ;;
            *)
                for val in $choice; do
                    if [[ "$val" =~ ^[0-9]+$ ]] && (( val >= 1 && val <= ${#ADDON_NAMES[@]} )); then
                        idx=$((val-1))
                        if is_selected "$idx"; then
                            for i in "${!selected_indices[@]}"; do
                                [[ ${selected_indices[i]} -eq $idx ]] && unset 'selected_indices[i]'
                            done
                            selected_indices=("${selected_indices[@]}")
                        else
                            selected_indices+=("$idx")
                        fi
                    else
                        echo -e "${R}Invalid option: $val${N}"; sleep 0.5
                    fi
                done
                ;;
        esac
    done
}

# ==========================================
# 🚀 MAIN SCRIPT ENTRY (SUPER MENU)
# ==========================================
while true; do
    show_banner
    echo -e "${WHITE}Select what you want to install:${NC}\n"
    echo -e "${CYAN}  [ 1 ] ${WHITE}Theme Installer ${GREEN}(Arix)${NC}"
    echo -e "${CYAN}  [ 2 ] ${WHITE}Theme Addon Installer ${BM}(Blueprint Mods)${NC}"
    echo -e "${CYAN}  [ 0 ] ${WHITE}Exit${NC}\n"
    
    echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
    read super_choice
    echo -ne "${NC}"
    
    case $super_choice in
        1) run_theme_installer ;;
        2) run_addon_installer ;;
        0) echo -e "\n${GREEN}Exiting... Have a great day!${NC}"; exit 0 ;;
        *) echo ""; warning "Invalid selection. Try again."; sleep 1 ;;
    esac
done
