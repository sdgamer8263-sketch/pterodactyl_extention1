cd /var/www/pterodactyl
mkdir -p app/Http/Controllers/Admin
mkdir -p app/Http/Controllers/Api/Client
mkdir -p app/Http/Requests/Api/Client
mkdir -p resources/scripts/api/tickets
mkdir -p resources/scripts/components/tickets
mkdir -p resources/scripts/routers
mkdir -p resources/views/admin/tickets

cd /var/www/pterodactyl
cat << 'EOF' > app/Http/Controllers/Admin/TicketsController.php
<?php 
namespace Pterodactyl\Http\Controllers\Admin; 
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Prologue\Alerts\Facades\Alert;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException; 

class TicketsController extends Controller {
    public static $statuses = [['name' => 'Waiting for admin...', 'color' => 'info'], ['name' => 'Waiting for client...', 'color' => 'warning'], ['name' => 'Closed', 'color' => 'danger']]; 
    public static $priorities = [['name' => 'Low', 'color' => 'primary'], ['name' => 'Medium', 'color' => 'warning'], ['name' => 'High', 'color' => 'success']]; 
    public function index(Request $request, $categoryId = 0) {
        return view('admin.tickets.list', [
            'tickets' => DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'users.name_first as firstname', 'users.name_last as lastname', 'servers.name as serverName'])->where(function ($table) use ($request) { if (!empty($request->input('status', ''))) { return $table->where('status_id', '=', (int) $request->input('status') - 1); } return $table; })->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('users', 'users.id', '=', 'tickets.user_id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->orderBy('updated_at', 'DESC')->paginate(10),
            'categories' => DB::table('ticket_categories')->get(), 'statuses' => TicketsController::$statuses, 'priorities' => TicketsController::$priorities,
            'createCategory' => Route::currentRouteName() == 'admin.tickets.categories.create', 'editCategory' => DB::table('ticket_categories')->where('id', '=', (int) $categoryId)->first(),
        ]);
    } 
    public function view(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'users.name_first as firstname', 'users.name_last as lastname', 'servers.name as serverName'])->where('tickets.id', '=', (int) $ticketId)->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('users', 'users.id', '=', 'tickets.user_id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->first(); 
        if (!$ticket) { throw new NotFoundHttpException('Ticket not found'); } 
        return view('admin.tickets.view', ['ticket' => $ticket, 'messages' => DB::table('ticket_messages')->select(['ticket_messages.*', 'users.name_first as firstname', 'users.name_last as lastname'])->where('ticket_id', '=', $ticket->id)->leftJoin('users', 'users.id', '=', 'ticket_messages.user_id')->orderBy('sent_at', 'DESC')->get(), 'statuses' => TicketsController::$statuses, 'priorities' => TicketsController::$priorities]);
    } 
    public function status(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->where('id', '=', (int) $ticketId)->first(); if (!$ticket) { throw new DisplayException('Ticket not found.'); } 
        $this->validate($request, ['status' => 'required|integer']); if (!isset(TicketsController::$statuses[$request->input('status')])) { throw new DisplayException('Invalid status.'); } 
        DB::table('tickets')->where('id', '=', $ticket->id)->update(['status_id' => $request->input('status'), 'updated_at' => Carbon::now()]); Alert::success('You\'ve successfully edited the ticket status.')->flash(); return redirect()->back();
    } 
    public function reply(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->where('id', '=', (int) $ticketId)->first(); if (!$ticket) { throw new DisplayException('Ticket not found.'); } if ($ticket->status_id == 2) { throw new DisplayException('Ticket is closed.'); } 
        $this->validate($request, ['message' => 'required|string']); 
        DB::table('tickets')->where('id', '=', $ticket->id)->update(['status_id' => 1, 'updated_at' => Carbon::now()]); 
        DB::table('ticket_messages')->insert(['ticket_id' => $ticket->id, 'user_id' => Auth::user()->id, 'message' => trim($request->input('message')), 'sent_at' => Carbon::now()]); 
        Alert::success('You\'ve successfully sent the message.')->flash(); return redirect()->back();
    } 
    public function createCategory(Request $request) {
        $this->validate($request, ['name' => 'required|string|max:40']); DB::table('ticket_categories')->insert(['name' => trim(strip_tags($request->input('name')))]); Alert::success('You\'ve successfully created the new category.')->flash(); return redirect()->route('admin.tickets');
    } 
    public function editCategory(Request $request, $categoryId) {
        $category = DB::table('ticket_categories')->where('id', '=', (int) $categoryId)->first(); if (!$category) { throw new DisplayException('Category not found.'); } 
        $this->validate($request, ['name' => 'required|string|max:40']); DB::table('ticket_categories')->where('id', '=', $category->id)->update(['name' => trim(strip_tags($request->input('name')))]); Alert::success('You\'ve successfully edited the category.')->flash(); return redirect()->route('admin.tickets');
    } 
    public function deleteCategory(Request $request) {
        $category = DB::table('ticket_categories')->where('id', '=', (int) $request->input('id', 0))->first(); if (!$category) { throw new DisplayException('Category not found.'); } 
        $categoryUsed = DB::table('tickets')->where('category_id', '=', $category->id)->get(); if (count($categoryUsed) > 0) { throw new DisplayException('Category is used by tickets.'); } 
        DB::table('ticket_categories')->where('id', '=', $category->id)->delete(); return ['success' => true];
    }
}
EOF
cd /var/www/pterodactyl
cat << 'EOF' > app/Http/Controllers/Api/Client/TicketsController.php
<?php 
namespace Pterodactyl\Http\Controllers\Api\Client; 
use Carbon\Carbon; use Illuminate\Support\Facades\DB; use Illuminate\Support\Facades\Auth; use Pterodactyl\Exceptions\DisplayException; use Pterodactyl\Http\Requests\Api\Client\TicketsRequest; use \Pterodactyl\Http\Controllers\Admin\TicketsController as AdminTicketController; 

class TicketsController extends ClientApiController {
    public function index(TicketsRequest $request) {
        return ['success' => true, 'data' => ['tickets' => DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'servers.name as serverName'])->where('tickets.user_id', '=', Auth::user()->id)->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->orderBy('updated_at', 'DESC')->get(), 'categories' => DB::table('ticket_categories')->get(), 'statuses' => AdminTicketController::$statuses, 'priorities' => AdminTicketController::$priorities, 'servers' => DB::table('servers')->select(['id', 'name'])->whereIn('id', Auth::user()->accessibleServers()->pluck('id')->all())->get()]];
    } 
    public function create(TicketsRequest $request) {
        $this->validate($request, ['subject' => 'required|string|max:50', 'message' => 'required|string|max:2000', 'priority' => 'required', 'category' => 'required|exists:ticket_categories,id']); 
        if (!isset(AdminTicketController::$priorities[$request->input('priority')])) { throw new DisplayException('Invalid priority'); } 
        if ($request->input('relatedServer', 0) != 0 && !in_array((int) $request->input('relatedServer'), Auth::user()->accessibleServers()->pluck('id')->all())) { throw new DisplayException('Related server not found.'); } 
        $ticketId = DB::table('tickets')->insertGetId(['user_id' => Auth::user()->id, 'subject' => trim(strip_tags($request->input('subject'))), 'status_id' => 0, 'priority_id' => (int) $request->input('priority'), 'category_id' => (int) $request->input('category'), 'related_server_id' => ((int) $request->input('relatedServer') == 0 ? null : (int) $request->input('relatedServer')), 'created_at' => Carbon::now(), 'updated_at' => Carbon::now()]); 
        DB::table('ticket_messages')->insert(['ticket_id' => $ticketId, 'user_id' => Auth::user()->id, 'message' => trim(strip_tags($request->input('message'))), 'sent_at' => Carbon::now()]); return ['success' => true];
    } 
    public function view(TicketsRequest $request, $ticketId) {
        $ticket = DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'servers.name as serverName', 'servers.uuidShort as uuidShort'])->where('tickets.id', '=', (int) $ticketId)->where('tickets.user_id', '=', Auth::user()->id)->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->first(); 
        if (!$ticket) { throw new DisplayException('Ticket not found.'); } 
        return ['success' => true, 'data' => ['ticket' => $ticket, 'messages' => DB::table('ticket_messages')->select(['ticket_messages.*', 'users.name_first as firstname', 'users.name_last as lastname'])->where('ticket_id', '=', $ticket->id)->leftJoin('users', 'users.id', '=', 'ticket_messages.user_id')->orderBy('sent_at', 'DESC')->get(), 'statuses' => AdminTicketController::$statuses, 'priorities' => AdminTicketController::$priorities]];
    } 
    public function message(TicketsRequest $request, $ticketId) {
        $ticket = DB::table('tickets')->where('id', '=', (int) $ticketId)->where('user_id', '=', Auth::user()->id)->first(); if (!$ticket) { throw new DisplayException('Ticket not found.'); } if ($ticket->status_id == 2) { throw new DisplayException('Ticket is closed.'); } 
        $this->validate($request, ['message' => 'required|string']); 
        DB::table('ticket_messages')->insert(['user_id' => Auth::user()->id, 'ticket_id' => $ticket->id, 'message' => trim(strip_tags($request->input('message'))), 'sent_at' => Carbon::now()]); DB::table('tickets')->where('id', '=', $ticket->id)->update(['status_id' => 0, 'updated_at' => Carbon::now()]); return ['success' => true];
    }
}
EOF
cat << 'EOF' > app/Http/Requests/Api/Client/TicketsRequest.php
<?php 
namespace Pterodactyl\Http\Requests\Api\Client; 
class TicketsRequest extends ClientApiRequest {
    public function authorize(): bool { if (!parent::authorize()) { return false; } return true; }
}
EOF
cd /var/www/pterodactyl
cat << 'EOF' > database/migrations/2022_04_09_104734_create_tickets_table.php
<?php 
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema; 
class CreateTicketsTable extends Migration {
    public function up() { Schema::create('tickets', function (Blueprint $table) { $table->id(); $table->integer('user_id'); $table->integer('status_id'); $table->integer('category_id'); $table->integer('priority_id'); $table->string('subject'); $table->integer('related_server_id')->nullable(); $table->dateTime('created_at'); $table->dateTime('updated_at'); }); } 
    public function down() { Schema::dropIfExists('tickets'); }
}
EOF
cat << 'EOF' > database/migrations/2022_04_09_104754_create_ticket_messages_table.php
<?php 
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema; 
class CreateTicketMessagesTable extends Migration {
    public function up() { Schema::create('ticket_messages', function (Blueprint $table) { $table->id(); $table->integer('ticket_id'); $table->integer('user_id'); $table->text('message'); $table->dateTime('sent_at'); }); } 
    public function down() { Schema::dropIfExists('ticket_messages'); }
}
EOF
cat << 'EOF' > database/migrations/2022_04_09_105917_create_ticket_categories_table.php
<?php 
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema; 
class CreateTicketCategoriesTable extends Migration {
    public function up() { Schema::create('ticket_categories', function (Blueprint $table) { $table->id(); $table->string('name'); }); } 
    public function down() { Schema::dropIfExists('ticket_categories'); }
}
EOF
cd /var/www/pterodactyl
cat << 'EOF' > resources/scripts/api/tickets/createTicket.ts
import http from '@/api/http'; 
export default (category: number, priority: number, message: string, subject: string, relatedServer: number): Promise<any> => {
    return new Promise((resolve, reject) => { http.post('/api/client/tickets/create', { category, priority, message, subject, relatedServer, }).then((data) => { resolve(data.data || []); }).catch(reject); });
};
EOF
cat << 'EOF' > resources/scripts/api/tickets/reply.ts
import http from '@/api/http'; 
export default (id: number, message: string): Promise<any> => {
    return new Promise((resolve, reject) => { http.post(`/api/client/tickets/${id}/message`, { message, }).then((data) => { resolve(data.data || []); }).catch(reject); });
};
EOF
cat << 'EOF' > resources/scripts/api/tickets/ticket.ts
import http from '@/api/http'; import { TicketResponse } from '@/components/tickets/TicketViewContainer'; 
export default async (id: number): Promise<TicketResponse> => {
    const { data } = await http.get(`/api/client/tickets/view/${id}`); return (data.data || []);
};
EOF
cat << 'EOF' > resources/scripts/api/tickets/tickets.ts
import http from '@/api/http'; import { TicketsResponse } from '@/components/tickets/TicketsContainer'; 
export default async (): Promise<TicketsResponse> => {
    const { data } = await http.get('/api/client/tickets'); return (data.data || []);
};
EOF

cd /var/www/pterodactyl
cat << 'EOF' > resources/scripts/components/tickets/TicketsContainer.tsx
import React, { useEffect } from 'react'; import PageContentBlock from '@/components/elements/PageContentBlock'; import useFlash from '@/plugins/useFlash'; import useSWR from 'swr'; import tickets from '@/api/tickets/tickets'; import Spinner from '@/components/elements/Spinner'; import TitledGreyBox from '@/components/elements/TitledGreyBox'; import { Formik, Form, FormikHelpers, Field as FormikField } from 'formik'; import { object, string } from 'yup'; import tw from 'twin.macro'; import Field from '@/components/elements/Field'; import Button from '@/components/elements/Button'; import Label from '@/components/elements/Label'; import FormikFieldWrapper from '@/components/elements/FormikFieldWrapper'; import Select from '@/components/elements/Select'; import { Textarea } from '@/components/elements/Input'; import createTicket from '@/api/tickets/createTicket'; import GreyRowBox from '@/components/elements/GreyRowBox'; import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'; import { faComment } from '@fortawesome/free-solid-svg-icons'; import styled from 'styled-components/macro'; import { NavLink } from 'react-router-dom'; 

const Code = styled.code`${tw`font-mono py-1 px-2 bg-neutral-900 rounded text-sm inline-block`}`; 
export interface TicketsResponse { tickets: any[]; categories: any[]; statuses: any[]; priorities: any[]; servers: any[]; } 
interface CreateForm { category: number; priority: number; message: string; subject: string; relatedServer: number; } 

export default () => {
    const { clearAndAddHttpError, clearFlashes, addFlash } = useFlash(); const { data, error, mutate } = useSWR<TicketsResponse>([ '/tickets' ], () => tickets()); 
    const onSubmit = ({ category, priority, message, relatedServer, subject }: CreateForm, { setSubmitting, resetForm }: FormikHelpers<CreateForm>) => {
        clearFlashes('tickets'); createTicket(category, priority, message, subject, relatedServer).then(() => { setSubmitting(false); resetForm(); mutate(); addFlash({ key: 'tickets', message: 'Success', title: 'success', type: 'success' }); }).catch((error) => { setSubmitting(false); clearAndAddHttpError({ key: 'tickets', error }); });
    }; 
    useEffect(() => { if (!error) { clearFlashes('tickets'); } else { clearAndAddHttpError({ key: 'tickets', error }); } }, [ error ]); 
    return (
        <PageContentBlock title={'Tickets'} showFlashKey={'tickets'}>
            {data ? <>
                <TitledGreyBox title={'New Ticket'}>
                    <Formik onSubmit={onSubmit} initialValues={{ category: data.categories[0]?.id || 0, priority: 0, subject: '', message: '', relatedServer: 0 }} validationSchema={object().shape({ subject: string().required('Subject is required').max(50), message: string().required('Message is required') })}>
                        {({ isSubmitting }) => (
                            <Form>
                                <div css={tw`flex flex-wrap`}>
                                    <div css={tw`mb-4 w-full lg:w-1/2`}><Field name={'subject'} label={'Subject'} /></div>
                                    <div css={tw`mb-4 w-full lg:w-2/12 lg:pl-4`}><Label>Category</Label><FormikFieldWrapper name={'category'}><FormikField as={Select} name={'category'}>{data.categories.map((item, key) => ( <option key={key} value={item.id}>{item.name}</option> ))}</FormikField></FormikFieldWrapper></div>
                                    <div css={tw`mb-4 w-full lg:w-2/12 lg:pl-4`}><Label>Priority</Label><FormikFieldWrapper name={'priority'}><FormikField as={Select} name={'priority'}>{data.priorities.map((item, key) => ( <option key={key} value={key}>{item.name}</option> ))}</FormikField></FormikFieldWrapper></div>
                                    <div css={tw`mb-4 w-full lg:w-2/12 lg:pl-4`}><Label>Related Server</Label><FormikFieldWrapper name={'relatedServer'}><FormikField as={Select} name={'relatedServer'}><option value={0}>- None -</option>{data.servers.map((item, key) => ( <option key={key} value={item.id}>{item.name}</option> ))}</FormikField></FormikFieldWrapper></div>
                                    <div css={tw`mb-4 w-full pt-2`}><Label>Message</Label><FormikFieldWrapper name={'message'}><FormikField as={Textarea} name={'message'} /></FormikFieldWrapper></div>
                                </div><div css={tw`flex justify-end`}><Button type={'submit'} disabled={isSubmitting} isLoading={isSubmitting}>Create</Button></div>
                            </Form>
                        )}
                    </Formik>
                </TitledGreyBox>
                {data.tickets.length < 1 ? <p css={tw`text-center text-sm text-neutral-400 pt-4 pb-4`}>There are no tickets.</p> :
                    (data.tickets.map((item) => (
                        <NavLink to={`/tickets/${item.id}`} key={`ticket-${item.id}`}>
                            <GreyRowBox $hoverable css={tw`flex-wrap md:flex-nowrap mt-2`}><div css={tw`flex items-center w-full md:w-auto`}><div css={tw`pl-4 pr-6 text-neutral-400`}><FontAwesomeIcon icon={faComment} /></div><div css={tw`flex-1 md:w-48 mr-4 overflow-hidden`}><Code>{item.subject}</Code><Label>Subject</Label></div><div css={tw`flex-1 md:w-80 mr-4`}><Code css={item.status_id === 0 ? tw`bg-primary-300 text-white` : (item.status_id === 1 ? tw`bg-yellow-500 text-white` : tw`bg-red-500 text-white`)}>{data.statuses[item.status_id].name}</Code><Label>Status</Label></div><div css={tw`flex-1 md:w-32 mr-4`}><Code>{item.category}</Code><Label>Category</Label></div><div css={tw`flex-1 md:w-16 mr-4`}><Code css={item.priority_id === 0 ? tw`bg-primary-500 text-white` : (item.priority_id === 1 ? tw`bg-yellow-500 text-white` : tw`bg-red-500 text-white`)}>{data.priorities[item.priority_id].name}</Code><Label>Priority</Label></div><div css={tw`flex-1 md:w-72 mr-4`}><Code>{item.updated_at}</Code><Label>Updated At</Label></div></div></GreyRowBox>
                        </NavLink>
                    )))
                }
            </> : <Spinner size={'large'} centered />}
        </PageContentBlock>
    );
};
EOF
cd /var/www/pterodactyl
cat << 'EOF' > resources/scripts/components/tickets/TicketViewContainer.tsx
import React, { useEffect } from 'react'; import PageContentBlock from '@/components/elements/PageContentBlock'; import useFlash from '@/plugins/useFlash'; import useSWR from 'swr'; import ticket from '@/api/tickets/ticket'; import { useParams } from 'react-router'; import Spinner from '@/components/elements/Spinner'; import tw from 'twin.macro'; import TitledGreyBox from '@/components/elements/TitledGreyBox'; import { FormikHelpers, Form, Formik, Field as FormikField } from 'formik'; import { object, string } from 'yup'; import Button from '@/components/elements/Button'; import Label from '@/components/elements/Label'; import FormikFieldWrapper from '@/components/elements/FormikFieldWrapper'; import { Textarea } from '@/components/elements/Input'; import reply from '@/api/tickets/reply'; import styled from 'styled-components/macro'; import { NavLink } from 'react-router-dom'; 
const Code = styled.code`${tw`font-mono py-1 px-2 bg-neutral-900 rounded text-sm inline-block`}`; 
export interface TicketResponse { ticket: any; messages: any[]; statuses: any[]; priorities: any[]; } 
interface Reply { message: string; } 
export default () => {
    // @ts-ignore
    const { id } = useParams(); const { clearFlashes, clearAndAddHttpError, addFlash } = useFlash(); const { data, error, mutate } = useSWR<TicketResponse>([ id, `/tickets/view/${id}` ], (id) => ticket(id)); 
    const sendReply = ({ message }: Reply, { setSubmitting, resetForm }: FormikHelpers<Reply>) => { clearFlashes('tickets:view'); reply(data?.ticket.id, message).then(() => { setSubmitting(false); resetForm(); mutate(); addFlash({ key: 'tickets', message: 'Success', title: 'success', type: 'success' }); }).catch((error) => { setSubmitting(false); clearAndAddHttpError({ key: 'tickets:view', error }); }); }; 
    useEffect(() => { if (!error) { clearFlashes('tickets:view'); } else { clearAndAddHttpError({ key: 'tickets:view', error }); } }, [ error ]); 
    return (
        <PageContentBlock title={'View Ticket'} showFlashKey={'tickets:view'}>
            {data ? <div css={tw`flex flex-wrap`}><div css={tw`w-full lg:w-8/12`}>
                {data.ticket.status_id !== 2 && <TitledGreyBox title={'Reply'} css={tw`mb-8`}><Formik onSubmit={sendReply} initialValues={{ message: '' }} validationSchema={object().shape({ message: string().required('Message is required').max(2000) })}>{({ isSubmitting }) => (<Form><div css={tw`flex flex-wrap`}><div css={tw`mb-4 w-full pt-2`}><Label>Message</Label><FormikFieldWrapper name={'message'}><FormikField as={Textarea} name={'message'} /></FormikFieldWrapper></div></div><div css={tw`flex justify-end`}><Button type={'submit'} disabled={isSubmitting} isLoading={isSubmitting}>Send</Button></div></Form>)}</Formik></TitledGreyBox>}
                {data.messages.map((item) => (<div css={tw`rounded shadow-md bg-neutral-700 mt-4`} key={`ticket-${item.id}`}><div css={tw`bg-neutral-900 rounded-t p-3 border-b border-black`}><p css={tw`float-right`}><small>{item.sent_at}</small></p><p css={tw`text-sm uppercase`}>{item.firstname} {item.lastname} ({data.ticket.user_id === item.user_id ? 'Client' : 'Admin'})</p></div><div css={tw`p-3`}><div dangerouslySetInnerHTML={{ __html: item.message }} /></div></div>))}
            </div><div css={tw`w-full lg:w-4/12 lg:pl-4`}><TitledGreyBox title={'Information'}><div css={tw`flex flex-wrap`}><b css={tw`w-full w-4/12 text-right pr-2 pb-1`}>Subject:</b><span css={tw`w-full w-6/12 pb-1`}>{data.ticket.subject}</span><b css={tw`w-full w-4/12 text-right pr-2 pb-1`}>Status:</b><span css={tw`w-full w-6/12 mb-1`}><Code css={data.ticket.status_id === 0 ? tw`bg-primary-300 text-white` : (data.ticket.status_id === 1 ? tw`bg-yellow-500 text-white` : tw`bg-red-500 text-white`)} style={{ fontSize: '0.8rem' }}>{data.statuses[data.ticket.status_id].name}</Code></span><b css={tw`w-full w-4/12 text-right pr-2 pb-1`}>Category:</b><span css={tw`w-full w-6/12 pb-1`}>{data.ticket.category}</span><b css={tw`w-full w-4/12 text-right pr-2 pb-1`}>Server:</b><span css={tw`w-full w-6/12 pb-1`}>{data.ticket.related_server_id === null ? <p>No</p> : <NavLink to={`/server/${data.ticket.uuidShort}`}>{data.ticket.serverName}</NavLink>}</span></div></TitledGreyBox></div></div>
            : <Spinner size={'large'} centered />}
        </PageContentBlock>
    );
};
EOF

cat << 'EOF' > resources/scripts/routers/TicketsRouter.tsx
import React from 'react'; import { Route, Switch } from 'react-router-dom'; import NavigationBar from '@/components/NavigationBar'; import { NotFound } from '@/components/elements/ScreenBlock'; import TransitionRouter from '@/TransitionRouter'; import TicketsContainer from '@/components/tickets/TicketsContainer'; import TicketViewContainer from '@/components/tickets/TicketViewContainer'; import { useLocation } from 'react-router'; import Spinner from '@/components/elements/Spinner'; 
export default () => {
    const location = useLocation(); 
    return (<><NavigationBar /><TransitionRouter><React.Suspense fallback={<Spinner centered />}><Switch location={location}><Route path={'/tickets'} exact><TicketsContainer /></Route><Route path={'/tickets/:id'} exact><TicketViewContainer /></Route><Route path={'*'}><NotFound /></Route></Switch></React.Suspense></TransitionRouter></>);
};
EOF
cd /var/www/pterodactyl
cat << 'EOF' > resources/views/admin/tickets/view.blade.php
@extends('layouts.admin') 
@section('title') View Ticket @endsection 
@section('content-header')
    <h1>Ticket - #{{ $ticket->id }} <small>Read / reply to opened ticket.</small></h1>
    <ol class="breadcrumb"><li><a href="{{ route('admin.index') }}">Admin</a></li><li><a href="{{ route('admin.tickets') }}">Tickets</a></li><li class="active">Ticket - #{{ $ticket->id }}</li></ol>
@endsection 
@section('content')
    <div class="row">
        @if ($ticket->status_id == 2) <div class="col-xs-12"><div class="alert alert-danger">This ticket is closed. Please re-open if you want to send message.</div></div> @endif
        <div class="col-xs-12 col-lg-8">
            @if ($ticket->status_id != 2)
                <div class="box box-success"><div class="box-header with-border"><h3 class="box-title">Reply</h3></div><form method="post" action="{{ route('admin.tickets.view.reply', $ticket->id) }}"><div class="box-body"><div class="form-group"><label for="message">Message</label><textarea id="message" name="message" class="form-control">{{ old('message') }}</textarea></div></div><div class="box-footer">{!! csrf_field() !!}<button type="submit" class="btn btn-success pull-right">Send</button></div></form></div>
            @endif
            @foreach ($messages as $message)
                <div class="box box-{{ $message->user_id == $ticket->user_id ? 'primary' : 'danger' }}"><div class="box-header with-border"><h3 class="box-title">{{ $message->firstname }} ({{ $message->user_id == $ticket->user_id ? 'Client' : 'Admin' }})</h3><div class="box-tools" style="padding-top: .4rem;">{{ $message->sent_at }}</div></div><div class="box-body">{!! $message->message !!}</div></div>
            @endforeach
        </div>
        <div class="col-xs-12 col-lg-4">
            <div class="box box-primary"><div class="box-header with-border"><h3 class="box-title">Information</h3></div><div class="box-body"><dl class="dl-horizontal"><dt style="padding-top: .35rem;">Subject:</dt><dd style="padding-top: .35rem;"><span class="label label-primary">{{ $ticket->subject }}</span></dd> <dt style="padding-top: .35rem;">Client:</dt><dd style="padding-top: .35rem;">{{ $ticket->firstname }}</dd> <dt style="padding-top: .35rem;">Status:</dt><dd style="padding-top: .35rem;"><span class="label label-{{ $statuses[$ticket->status_id]['color'] }}">{{ $statuses[$ticket->status_id]['name'] }}</span></dd> <dt style="padding-top: .35rem;">Category:</dt><dd style="padding-top: .35rem;"><code>{{ $ticket->category }}</code></dd></dl></div></div>
            <div class="box box-warning">
                <div class="box-header with-border"><h3 class="box-title">Manage</h3></div>
                <form method="post" action="{{ route('admin.tickets.view.status', $ticket->id) }}">
                    <div class="box-body"><p>If you set as <b>Closed</b>, you can't send message until the ticket will be re-opened.</p><div class="form-group"><label for="status">Status</label><select id="status" name="status" class="form-control">@foreach ($statuses as $key => $status)<option value="{{ $key }}" {{ $ticket->status_id == $key ? 'selected' : '' }}>{{ $status['name'] }}</option>@endforeach</select></div></div><div class="box-footer">{!! csrf_field() !!}<button type="submit" class="btn btn-success pull-right">Save</button></div>
                </form>
            </div>
        </div>
    </div>
@endsection 
@section('footer-scripts')
    @parent
    <script src="//cdn.ckeditor.com/ckeditor5/12.4.0/classic/ckeditor.js"></script> 
    <script> function MinHeightPlugin(editor) { this.editor = editor; } MinHeightPlugin.prototype.init = function () { this.editor.ui.view.editable.extendTemplate({ attributes: { style: { minHeight: '100px', }, }, }); }; ClassicEditor.builtinPlugins.push(MinHeightPlugin); ClassicEditor.create(document.querySelector('#message')).catch(error => { console.error(error); }); </script>
@endsection
EOF

cd /var/www/pterodactyl
cat << 'EOF' > patch_all.js
const fs = require('fs');
let adminRoutes = fs.readFileSync('routes/admin.php', 'utf8');
if (!adminRoutes.includes('TicketsController::class')) {
    const adminAppend = `\nRoute::group(['prefix' => 'tickets'], function () { Route::get('/', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'index'])->name('admin.tickets'); Route::get('/view/{ticketId}', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'view'])->name('admin.tickets.view'); Route::post('/view/{ticketId}/status', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'status'])->name('admin.tickets.view.status'); Route::post('/view/{ticketId}/reply', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'reply'])->name('admin.tickets.view.reply'); Route::post('/categories/create', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'createCategory'])->name('admin.tickets.categories.create'); Route::get('/categories/create', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'index'])->name('admin.tickets.categories.create'); Route::get('/categories/view/{categoryId}', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'index'])->name('admin.tickets.categories.view'); Route::post('/categories/edit/{categoryId}', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'editCategory'])->name('admin.tickets.categories.edit'); Route::delete('/categories/delete', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'deleteCategory'])->name('admin.tickets.categories.delete'); });\n`;
    fs.appendFileSync('routes/admin.php', adminAppend);
}
let clientRoutes = fs.readFileSync('routes/api-client.php', 'utf8');
if (!clientRoutes.includes('TicketsController::class, \'message\'')) {
    const clientAppend = `\nRoute::group(['prefix' => 'tickets'], function () { Route::get('/', [\\Pterodactyl\\Http\\Controllers\\Api\\Client\\TicketsController::class, 'index']); Route::post('/create', [\\Pterodactyl\\Http\\Controllers\\Api\\Client\\TicketsController::class, 'create']); Route::get('/view/{ticketId}', [\\Pterodactyl\\Http\\Controllers\\Api\\Client\\TicketsController::class, 'view']); Route::post('/{ticketId}/message', [\\Pterodactyl\\Http\\Controllers\\Api\\Client\\TicketsController::class, 'message']); });\n`;
    fs.appendFileSync('routes/api-client.php', clientAppend);
}
let adminBlade = fs.readFileSync('resources/views/layouts/admin.blade.php', 'utf8');
if (!adminBlade.includes('admin.tickets')) {
    adminBlade = adminBlade.replace('<li class="header">BASIC ADMINISTRATION</li>', '<li class="header">BASIC ADMINISTRATION</li>\n                    <li class="{{ Route::currentRouteNamed(\'admin.tickets*\') ? \'active\' : \'\' }}"><a href="{{ route(\'admin.tickets\') }}"><i class="fa fa-ticket"></i> <span>Tickets</span></a></li>');
    fs.writeFileSync('resources/views/layouts/admin.blade.php', adminBlade);
}
let appTsx = fs.readFileSync('resources/scripts/components/App.tsx', 'utf8');
if (!appTsx.includes('TicketsRouter')) {
    appTsx = appTsx.replace("import DashboardRouter from '@/routers/DashboardRouter';", "import DashboardRouter from '@/routers/DashboardRouter';\nimport TicketsRouter from '@/routers/TicketsRouter';");
    appTsx = appTsx.replace("<Route path={'/server/:id'} component={ServerRouter} />", "<Route path={'/server/:id'} component={ServerRouter} />\n                            <Route path={'/tickets'} component={TicketsRouter} />");
    fs.writeFileSync('resources/scripts/components/App.tsx', appTsx);
}
EOF
node patch_all.js && rm patch_all.js

php artisan migrate --force
chown -R www-data:www-data /var/www/pterodactyl/*
export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"
yarn build:production
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl

cat << 'EOF' > patch_500.php
<?php
$file = "app/Http/Controllers/Admin/TicketsController.php";
if(file_exists($file)) {
    $content = file_get_contents($file);
    // ক্র্যাশ করা Alert Facade মুছে ফেলা হচ্ছে
    $content = str_replace("use Prologue\Alerts\Facades\Alert;", "", $content);
    // Pterodactyl এর নেটিভ সেফ Alert সিস্টেম বসানো হচ্ছে
    $content = str_replace("Alert::success", "app(\Prologue\Alerts\AlertsMessageBag::class)->success", $content);
    
    file_put_contents($file, $content);
    echo "✅ 500 Server Error Fixed Successfully!\n";
}
EOF

php patch_500.php
rm patch_500.php

# ক্যাশ ক্লিয়ার করা হচ্ছে
php artisan optimize:clear
cd /var/www/pterodactyl
cat << 'EOF' > app/Http/Controllers/Admin/TicketsController.php
<?php 
namespace Pterodactyl\Http\Controllers\Admin; 
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException; 

class TicketsController extends Controller {
    public static $statuses = [['name' => 'Waiting for admin...', 'color' => 'info'], ['name' => 'Waiting for client...', 'color' => 'warning'], ['name' => 'Closed', 'color' => 'danger']]; 
    public static $priorities = [['name' => 'Low', 'color' => 'primary'], ['name' => 'Medium', 'color' => 'warning'], ['name' => 'High', 'color' => 'success']]; 
    public function index(Request $request, $categoryId = 0) {
        return view('admin.tickets.list', ['tickets' => DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'users.name_first as firstname', 'users.name_last as lastname', 'servers.name as serverName'])->where(function ($table) use ($request) { if (!empty($request->input('status', ''))) { return $table->where('status_id', '=', (int) $request->input('status') - 1); } return $table; })->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('users', 'users.id', '=', 'tickets.user_id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->orderBy('updated_at', 'DESC')->paginate(10), 'categories' => DB::table('ticket_categories')->get(), 'statuses' => TicketsController::$statuses, 'priorities' => TicketsController::$priorities, 'createCategory' => Route::currentRouteName() == 'admin.tickets.categories.create', 'editCategory' => DB::table('ticket_categories')->where('id', '=', (int) $categoryId)->first()]);
    } 
    public function view(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->select(['tickets.*', 'ticket_categories.name as category', 'users.name_first as firstname', 'users.name_last as lastname', 'servers.name as serverName'])->where('tickets.id', '=', (int) $ticketId)->leftJoin('ticket_categories', 'tickets.category_id', '=', 'ticket_categories.id')->leftJoin('users', 'users.id', '=', 'tickets.user_id')->leftJoin('servers', 'servers.id', '=', 'tickets.related_server_id')->first(); if (!$ticket) { throw new NotFoundHttpException('Ticket not found'); } 
        return view('admin.tickets.view', ['ticket' => $ticket, 'messages' => DB::table('ticket_messages')->select(['ticket_messages.*', 'users.name_first as firstname', 'users.name_last as lastname'])->where('ticket_id', '=', $ticket->id)->leftJoin('users', 'users.id', '=', 'ticket_messages.user_id')->orderBy('sent_at', 'DESC')->get(), 'statuses' => TicketsController::$statuses, 'priorities' => TicketsController::$priorities]);
    } 
    public function status(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->where('id', '=', (int) $ticketId)->first(); if (!$ticket) { throw new DisplayException('Ticket not found.'); } 
        $this->validate($request, ['status' => 'required|integer']); if (!isset(TicketsController::$statuses[$request->input('status')])) { throw new DisplayException('Invalid status.'); } 
        DB::table('tickets')->where('id', '=', $ticket->id)->update(['status_id' => $request->input('status'), 'updated_at' => Carbon::now()]); return redirect()->back();
    } 
    public function reply(Request $request, $ticketId) {
        $ticket = DB::table('tickets')->where('id', '=', (int) $ticketId)->first(); if (!$ticket) { throw new DisplayException('Ticket not found.'); } if ($ticket->status_id == 2) { throw new DisplayException('Ticket is closed.'); } 
        $this->validate($request, ['message' => 'required|string']); 
        DB::table('tickets')->where('id', '=', $ticket->id)->update(['status_id' => 1, 'updated_at' => Carbon::now()]); DB::table('ticket_messages')->insert(['ticket_id' => $ticket->id, 'user_id' => Auth::user()->id, 'message' => trim($request->input('message')), 'sent_at' => Carbon::now()]); return redirect()->back();
    } 
    public function createCategory(Request $request) {
        $this->validate($request, ['name' => 'required|string|max:40']); DB::table('ticket_categories')->insert(['name' => trim(strip_tags($request->input('name')))]); return redirect()->route('admin.tickets');
    } 
    public function editCategory(Request $request, $categoryId) {
        $category = DB::table('ticket_categories')->where('id', '=', (int) $categoryId)->first(); if (!$category) { throw new DisplayException('Category not found.'); } 
        $this->validate($request, ['name' => 'required|string|max:40']); DB::table('ticket_categories')->where('id', '=', $category->id)->update(['name' => trim(strip_tags($request->input('name')))]); return redirect()->route('admin.tickets');
    } 
    public function deleteCategory(Request $request) {
        $category = DB::table('ticket_categories')->where('id', '=', (int) $request->input('id', 0))->first(); if (!$category) { throw new DisplayException('Category not found.'); } 
        $categoryUsed = DB::table('tickets')->where('category_id', '=', $category->id)->get(); if (count($categoryUsed) > 0) { throw new DisplayException('Category is used by tickets.'); } 
        DB::table('ticket_categories')->where('id', '=', $category->id)->delete(); return ['success' => true];
    }
}
EOF
cd /var/www/pterodactyl
cat << 'EOF' > patch_nav.js
const fs = require('fs');
const file = 'resources/scripts/components/NavigationBar.tsx';
let content = fs.readFileSync(file, 'utf8');

if (!content.includes("to={'/tickets'}")) {
    const accountMatch = content.match(/(<NavLink\s+to=\{(?:'|")\/account(?:'|")\}[^>]*>[\s\S]*?<\/NavLink>)/);
    if (accountMatch) {
        let ticketLink = accountMatch[1]
            .replace(/\/account/g, '/tickets')
            .replace(/Account/g, 'Tickets')
            .replace(/account/g, 'tickets')
            .replace(/faUserCircle/g, 'faTicketAlt')
            .replace(/faUser/g, 'faTicketAlt');
            
        content = content.replace(accountMatch[1], accountMatch[1] + '\n' + ticketLink);
        
        if(!content.includes('faTicketAlt')) {
            content = content.replace(/faUserCircle/, "faUserCircle, faTicketAlt");
            content = content.replace(/faUser,/, "faUser, faTicketAlt,");
        }
        fs.writeFileSync(file, content);
        console.log("✅ NavigationBar patched automatically!");
    } else {
        console.log("❌ Could not find Account link.");
    }
} else {
    console.log("✅ Tickets link already exists.");
}
EOF
node patch_nav.js
rm patch_nav.js
cd /var/www/pterodactyl
chown -R www-data:www-data /var/www/pterodactyl/*
export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"

# প্যানেল রিবিল্ড
yarn build:production
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl

# অটোমেটিকভাবে routes.ts ফাইলে Ticket রাউট ইনজেক্ট করা হচ্ছে
cat << 'EOF' > patch_server_ticket.js
const fs = require('fs');
const path = 'resources/scripts/routers/routes.ts';
let file = fs.readFileSync(path, 'utf8'); 

if(!file.includes('TicketsContainer')) {
    // ইম্পোর্ট অ্যাড করা হচ্ছে
    file = file.replace(
        "import AccountSecurityContainer from '@/components/dashboard/account/AccountSecurityContainer';",
        "import AccountSecurityContainer from '@/components/dashboard/account/AccountSecurityContainer';\nimport TicketsContainer from '@/components/tickets/TicketsContainer';"
    );
    
    // সার্ভারের রুটের ভেতর Ticket অ্যাড করা হচ্ছে (ticket এবং tickets দুটোই দেওয়া হলো সেফটির জন্য)
    const ticketRoute = `
        {
            path: '/ticket',
            permission: null,
            name: 'Ticket',
            component: TicketsContainer,
        },
        {
            path: '/tickets',
            permission: null,
            name: 'Tickets',
            component: TicketsContainer,
        },`;
    
    file = file.replace(/server:\s*\[/, "server: [" + ticketRoute);
    
    fs.writeFileSync(path, file);
    console.log("✅ routes.ts patched successfully for Server Tickets!");
} else {
    console.log("✅ routes.ts is already patched.");
}
EOF

node patch_server_ticket.js
rm patch_server_ticket.js

# প্যানেল রিবিল্ড করা হচ্ছে
chown -R www-data:www-data /var/www/pterodactyl/*
export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"
yarn build:production
php artisan view:clear
cd /var/www/pterodactyl

cat << 'EOF' > fix_routes_clean.js
const fs = require('fs');
const path = 'resources/scripts/routers/routes.ts';
let file = fs.readFileSync(path, 'utf8'); 

// ডাবল রুট থাকলে তা সরিয়ে শুধু /tickets রুট রাখা হচ্ছে
if (file.includes("path: '/ticket',")) {
    file = file.replace(/{\s*path:\s*'\/ticket',[\s\S]*?component:\s*TicketViewContainer,\s*},/, '');
    fs.writeFileSync(path, file);
    console.log("✅ Cleaned up extra /ticket route!");
}
EOF

node fix_routes_clean.js
rm fix_routes_clean.js

# প্যানেল রিবিল্ড করা হচ্ছে
chown -R www-data:www-data /var/www/pterodactyl/*
export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"
yarn build:production
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl

cat << 'EOF' > fix_routes_thorough.js
const fs = require('fs');
const path = 'resources/scripts/routers/routes.ts';
let file = fs.readFileSync(path, 'utf8'); 

// /ticket সম্পর্কিত ব্লকটি পুরোপুরি রিমুভ করা হচ্ছে
file = file.replace(/{\s*path:\s*'\/ticket',[^}]*?},/gs, '');

fs.writeFileSync(path, file);
console.log("✅ Completely removed /ticket from routes.ts!");
EOF

node fix_routes_thorough.js
rm fix_routes_thorough.js

# প্যানেল রিবিল্ড করা হচ্ছে
chown -R www-data:www-data /var/www/pterodactyl/*
export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"
yarn build:production
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl

# ১. Admin Controller এ Delete মেথড যুক্ত করা হচ্ছে
cat << 'EOF' > patch_admin_delete.php
<?php
$file = 'app/Http/Controllers/Admin/TicketsController.php';
$content = file_get_contents($file);

if (!strpos($content, 'public function deleteTicket')) {
    $deleteMethod = '
    public function deleteTicket(Request $request, $ticketId) {
        $ticket = DB::table(\'tickets\')->where(\'id\', '=', (int) $ticketId)->first();
        if (!$ticket) { throw new DisplayException(\'Ticket not found.\'); }
        
        DB::table(\'ticket_messages\')->where(\'ticket_id\', '=', $ticket->id)->delete();
        DB::table(\'tickets\')->where(\'id\', '=', $ticket->id)->delete();
        
        return [\'success\' => true];
    }
}
';
    // শেষের ব্র্যাকেট ঠিক রেখে মেথডটি বসানো হচ্ছে
    $content = preg_replace('/}\s*$/', $deleteMethod, $content);
    file_put_contents($file, $content);
    echo "✅ Admin Controller patched with deleteTicket!\n";
}
EOF
php patch_admin_delete.php
rm patch_admin_delete.php


# ২. Admin Route এ ডিলিট রাউট যুক্ত করা হচ্ছে
cat << 'EOF' > patch_admin_route.php
<?php
$file = 'routes/admin.php';
$content = file_get_contents($file);

if (!strpos($content, 'admin.tickets.delete')) {
    $routeCode = "    Route::delete('/view/{ticketId}/delete', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'deleteTicket'])->name('admin.tickets.delete');\n});";
    $content = str_replace("});", $routeCode, $content);
    file_put_contents($file, $content);
    echo "✅ Admin Route patched!\n";
}
EOF
php patch_admin_route.php
rm patch_admin_route.php


# ৩. Admin View Blade এ ডিলিট বাটন ও JavaScript যুক্ত করা হচ্ছে
cat << 'EOF' > resources/views/admin/tickets/view.blade.php
@extends('layouts.admin') 
@section('title') View Ticket @endsection 
@section('content-header')
    <h1>Ticket - #{{ $ticket->id }} <small>Read / reply to opened ticket.</small></h1>
    <ol class="breadcrumb"><li><a href="{{ route('admin.index') }}">Admin</a></li><li><a href="{{ route('admin.tickets') }}">Tickets</a></li><li class="active">Ticket - #{{ $ticket->id }}</li></ol>
@endsection 
@section('content')
    <div class="row">
        @if ($ticket->status_id == 2) <div class="col-xs-12"><div class="alert alert-danger">This ticket is closed. Please re-open if you want to send message.</div></div> @endif
        <div class="col-xs-12 col-lg-8">
            @if ($ticket->status_id != 2)
                <div class="box box-success"><div class="box-header with-border"><h3 class="box-title">Reply</h3></div><form method="post" action="{{ route('admin.tickets.view.reply', $ticket->id) }}"><div class="box-body"><div class="form-group"><label for="message">Message</label><textarea id="message" name="message" class="form-control">{{ old('message') }}</textarea></div></div><div class="box-footer">{!! csrf_field() !!}<button type="submit" class="btn btn-success pull-right">Send</button></div></form></div>
            @endif
            @foreach ($messages as $message)
                <div class="box box-{{ $message->user_id == $ticket->user_id ? 'primary' : 'danger' }}"><div class="box-header with-border"><h3 class="box-title">{{ $message->firstname }} ({{ $message->user_id == $ticket->user_id ? 'Client' : 'Admin' }})</h3><div class="box-tools" style="padding-top: .4rem;">{{ $message->sent_at }}</div></div><div class="box-body">{!! $message->message !!}</div></div>
            @endforeach
        </div>
        <div class="col-xs-12 col-lg-4">
            <div class="box box-primary"><div class="box-header with-border"><h3 class="box-title">Information</h3></div><div class="box-body"><dl class="dl-horizontal"><dt style="padding-top: .35rem;">Subject:</dt><dd style="padding-top: .35rem;"><span class="label label-primary">{{ $ticket->subject }}</span></dd> <dt style="padding-top: .35rem;">Client:</dt><dd style="padding-top: .35rem;">{{ $ticket->firstname }}</dd> <dt style="padding-top: .35rem;">Status:</dt><dd style="padding-top: .35rem;"><span class="label label-{{ $statuses[$ticket->status_id]['color'] }}">{{ $statuses[$ticket->status_id]['name'] }}</span></dd> <dt style="padding-top: .35rem;">Category:</dt><dd style="padding-top: .35rem;"><code>{{ $ticket->category }}</code></dd></dl></div></div>
            <div class="box box-warning">
                <div class="box-header with-border"><h3 class="box-title">Manage</h3></div>
                <form method="post" action="{{ route('admin.tickets.view.status', $ticket->id) }}">
                    <div class="box-body"><p>If you set as <b>Closed</b>, you can't send message until the ticket will be re-opened.</p><div class="form-group"><label for="status">Status</label><select id="status" name="status" class="form-control">@foreach ($statuses as $key => $status)<option value="{{ $key }}" {{ $ticket->status_id == $key ? 'selected' : '' }}>{{ $status['name'] }}</option>@endforeach</select></div></div><div class="box-footer">{!! csrf_field() !!}<button type="submit" class="btn btn-success pull-right">Save</button></div>
                </form>
            </div>
            <div class="box box-danger">
                <div class="box-header with-border"><h3 class="box-title">Danger Zone</h3></div>
                <div class="box-body">
                    <p>Delete this ticket and clean up all associated messages from storage/database.</p>
                    <button id="delete-ticket-btn" class="btn btn-danger btn-block"><i class="fa fa-trash"></i> Delete Ticket</button>
                </div>
            </div>
        </div>
    </div>
@endsection 
@section('footer-scripts')
    @parent
    <script src="//cdn.ckeditor.com/ckeditor5/12.4.0/classic/ckeditor.js"></script> 
    <script>
        function MinHeightPlugin(editor) { this.editor = editor; } 
        MinHeightPlugin.prototype.init = function () { this.editor.ui.view.editable.extendTemplate({ attributes: { style: { minHeight: '100px', }, }, }); }; 
        ClassicEditor.builtinPlugins.push(MinHeightPlugin);
        ClassicEditor.create(document.querySelector('#message')).catch(error => { console.error(error); });

        $('#delete-ticket-btn').click(function (event) {
            event.preventDefault();
            swal({
                title: '',
                type: 'warning',
                text: 'Are you sure you want to delete this ticket and clean its messages?',
                showCancelButton: true,
                confirmButtonText: 'Delete',
                confirmButtonColor: '#d9534f',
                closeOnConfirm: false,
                showLoaderOnConfirm: true,
                cancelButtonText: 'Cancel',
            }, function () {
                $.ajax({
                    method: 'DELETE',
                    url: '{{ route("admin.tickets.delete", $ticket->id) }}',
                    headers: {'X-CSRF-TOKEN': $('meta[name="_token"]').attr('content')}
                }).done(() => {
                    swal({
                        type: 'success',
                        title: 'Success!',
                        text: 'Ticket has been deleted successfully.'
                    }, function() {
                        window.location.href = '{{ route("admin.tickets") }}';
                    });
                }).fail((jqXHR) => {
                    swal({
                        type: 'error',
                        title: 'Ooops!',
                        text: (typeof jqXHR.responseJSON.error !== 'undefined') ? jqXHR.responseJSON.error : 'A system error has occurred!'
                    });
                });
            });
        });
    </script>
@endsection
EOF

# ক্যাশ ক্লিয়ার ও অপ্টিমাইজ করা
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl

cat << 'EOF' > fix_delete_final.php
<?php
// ১. Admin Controller এ Delete ফাংশন পারফেক্ট করা
$controllerFile = 'app/Http/Controllers/Admin/TicketsController.php';
$controllerContent = file_get_contents($controllerFile);

if (strpos($controllerContent, 'public function deleteTicket') === false) {
    $deleteMethod = '
    public function deleteTicket($ticketId) {
        \\Illuminate\\Support\\Facades\\DB::table(\'ticket_messages\')->where(\'ticket_id\', \'=\', $ticketId)->delete();
        \\Illuminate\\Support\\Facades\\DB::table(\'tickets\')->where(\'id\', \'=\', $ticketId)->delete();
        return [\'success\' => true];
    }
}
';
    $controllerContent = preg_replace('/}\s*$/', $deleteMethod, $controllerContent);
    file_put_contents($controllerFile, $controllerContent);
}

// ২. Admin Route এ সরাসরি ইউআরএল রাউট বসানো
$routeFile = 'routes/admin.php';
$routeContent = file_get_contents($routeFile);

if (strpos($routeContent, 'admin.tickets.delete') === false) {
    $routeCode = "\n    Route::delete('/view/{ticketId}/delete', [\\Pterodactyl\\Http\\Controllers\\Admin\\TicketsController::class, 'deleteTicket']);\n});";
    $routeContent = str_replace("});", $routeCode, $routeContent);
    file_put_contents($routeFile, $routeContent);
}

// ৩. View Blade ফাইলের AJAX ইউআরএল ফিক্স করা
$bladeFile = 'resources/views/admin/tickets/view.blade.php';
$bladeContent = file_get_contents($bladeFile);

// পুরনো AJAX কোডটি সরিয়ে নতুন সহজ কোড বসানো হচ্ছে
$oldAjax = 'url: \'' . '{{ route("admin.tickets.delete", $ticket->id) }}' . '\'';
$newAjax = 'url: \'/admin/tickets/view/' . '{{ $ticket->id }}' . '/delete\'';

$bladeContent = str_replace($oldAjax, $newAjax, $bladeContent);
// যদি আগের ফিক্সের কারণে অন্যরকম হয়ে থাকে তার জন্য বিকল্প রিপ্লেস
$bladeContent = preg_replace('/url:\s*\'\/admin\/tickets\/view\/\'\s*\+\s*\{\{\s*\$ticket->id\s*\}\}\s*\+\s*\'\/delete\'/', 'url: \'/admin/tickets/view/{{ $ticket->id }}/delete\'', $bladeContent);

file_put_contents($bladeFile, $bladeContent);
echo "✅ Everything is successfully force-fixed!\n";
EOF

php fix_delete_final.php
rm fix_delete_final.php

# ক্যাশ ক্লিয়ার করা হচ্ছে
php artisan route:clear
php artisan optimize:clear
cd /var/www/pterodactyl

chown -R www-data:www-data /var/www/pterodactyl/*

chown -R www-data:www-data /var/www/pterodactyl/.*

chmod -R 755 storage/* bootstrap/cache/

php artisan optimize:clear
