import { Head } from '@inertiajs/react';
import {
    AlertTriangle,
    Bot,
    Database,
    FileCheck2,
    Gauge,
    RadioTower,
    Scale,
    ShieldCheck,
} from 'lucide-react';
import { dashboard } from '@/routes';

export default function Dashboard() {
    const operations = [
        ['LLM decisions', Bot, 'No pending review data'],
        ['Reports and pauses', AlertTriangle, 'No active reports'],
        ['Resolver disputes', Scale, 'No open disputes'],
        ['Issuer roots', FileCheck2, 'No root projection available'],
        ['Paymaster quotas', Gauge, 'No live sponsor telemetry'],
        ['Relayer health', RadioTower, 'No live relayer telemetry'],
        ['PostgreSQL projection', Database, 'No indexed head available'],
        ['RPC health', ShieldCheck, 'No RPC endpoint configured'],
    ] as const;

    return (
        <>
            <Head title="Dashboard" />
            <div className="flex h-full flex-1 flex-col gap-6 overflow-x-auto rounded-xl p-4 md:p-6">
                <header>
                    <p className="text-sm font-black tracking-wider text-primary uppercase">
                        Raygir operations
                    </p>
                    <h1 className="mt-2 text-3xl font-black">
                        Operator control plane
                    </h1>
                    <p className="mt-3 max-w-3xl leading-7 text-muted-foreground">
                        Live values appear only when their PostgreSQL projection
                        or network service is configured. Privileged actions are
                        unavailable without immutable role and audit-event
                        support.
                    </p>
                </header>
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    {operations.map(([title, Icon, state]) => (
                        <section
                            key={title}
                            className="rounded-2xl border bg-card p-5 shadow-sm"
                        >
                            <Icon
                                className="size-6 text-primary"
                                aria-hidden="true"
                            />
                            <h2 className="mt-4 font-black">{title}</h2>
                            <p className="mt-2 text-sm leading-6 text-muted-foreground">
                                {state}
                            </p>
                            <span className="mt-4 inline-flex rounded-full bg-muted px-3 py-1 text-xs font-bold">
                                Unavailable
                            </span>
                        </section>
                    ))}
                </div>
            </div>
        </>
    );
}

Dashboard.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
    ],
};
