import { Head, Link, usePage } from '@inertiajs/react';
import { ArrowUpLeft, CheckCircle2, Globe2, ShieldCheck } from 'lucide-react';
import { dashboard, discovery, login } from '@/routes';
import { onboarding } from '@/routes/wallet';

type Locale = 'fa' | 'en';

const copy = {
    fa: {
        title: 'رأی‌گیر؛ زیرساخت رأی‌گیری و بازارهای پیش‌بینی خصوصی',
        description:
            'یک شبکه پژوهشی دوزبانه برای نظرسنجی مدنی، بازار پیش‌بینی و تسویه قابل ممیزی روی زنجیره سپهر.',
        badge: 'شبکه پژوهشی • دارایی‌های آزمایشی بدون ارزش مالی',
        enter: 'ساخت گاوصندوق محلی',
        operator: 'ورود اپراتور',
        dashboard: 'داشبورد اپراتور',
        language: 'English',
        privacyTitle: 'حریم خصوصی دقیق، نه ادعای مطلق',
        privacyText:
            'مدارک و تأمین مالی می‌توانند پنهان بمانند؛ انتخاب‌های ناشناس پس از بسته‌شدن نظرسنجی منتشر می‌شوند.',
        modes: ['نظرسنجی مدنی', 'استخر پیش‌بینی', 'بازار سفارش پیوسته'],
    },
    en: {
        title: 'Raygir: private voting and prediction-market infrastructure',
        description:
            'A bilingual research network for civic polls, prediction markets, and auditable settlement on Sepehr.',
        badge: 'Research network • test assets have no monetary value',
        enter: 'Create local vault',
        operator: 'Operator sign in',
        dashboard: 'Operator dashboard',
        language: 'فارسی',
        privacyTitle: 'Precise privacy, never absolute claims',
        privacyText:
            'Credentials and funding can remain private; anonymous selections are published after a poll closes.',
        modes: ['Civic polls', 'Prediction pools', 'Continuous order book'],
    },
};

export default function Welcome() {
    const { auth, locale } = usePage().props as unknown as {
        auth: { user: { id: number } | null };
        locale: Locale;
    };
    const text = copy[locale];
    const alternateLocale: Locale = locale === 'fa' ? 'en' : 'fa';

    return (
        <>
            <Head title={locale === 'fa' ? 'خانه' : 'Home'} />
            <main className="min-h-screen overflow-hidden bg-background text-foreground">
                <div className="pointer-events-none absolute inset-x-0 top-0 h-[34rem] bg-[radial-gradient(circle_at_30%_20%,color-mix(in_oklab,var(--primary)_18%,transparent),transparent_55%)]" />
                <header className="relative mx-auto flex max-w-7xl items-center justify-between px-5 py-5 md:px-8">
                    <Link
                        href={discovery({ locale })}
                        className="flex items-center gap-3"
                        aria-label="Raygir"
                    >
                        <span className="grid size-10 place-items-center rounded-xl bg-primary font-black text-primary-foreground">
                            ر
                        </span>
                        <span className="text-xl font-black tracking-tight">
                            Raygir <span className="text-primary">رأی‌گیر</span>
                        </span>
                    </Link>
                    <div className="flex items-center gap-2">
                        <Link
                            href={discovery({ locale: alternateLocale })}
                            className="inline-flex min-h-11 items-center gap-2 rounded-xl px-3 text-sm font-semibold hover:bg-muted"
                        >
                            <Globe2 className="size-4" /> {text.language}
                        </Link>
                        <Link
                            href={auth.user ? dashboard() : login()}
                            className="hidden min-h-11 items-center rounded-xl border bg-card px-4 text-sm font-semibold shadow-sm hover:bg-muted sm:inline-flex"
                        >
                            {auth.user ? text.dashboard : text.operator}
                        </Link>
                    </div>
                </header>
                <section className="relative mx-auto grid max-w-7xl gap-12 px-5 pt-16 pb-20 md:px-8 lg:grid-cols-[1.15fr_.85fr] lg:items-center lg:pt-24">
                    <div>
                        <p className="mb-6 inline-flex items-center gap-2 rounded-full border border-primary/25 bg-primary/10 px-4 py-2 text-sm font-bold text-primary">
                            <ShieldCheck className="size-4" /> {text.badge}
                        </p>
                        <h1 className="max-w-4xl text-4xl leading-[1.15] font-black tracking-tight sm:text-5xl lg:text-7xl">
                            {text.title}
                        </h1>
                        <p className="mt-6 max-w-2xl text-lg leading-8 text-muted-foreground">
                            {text.description}
                        </p>
                        <div className="mt-9 flex flex-wrap gap-3">
                            <Link
                                href={onboarding({ locale })}
                                className="inline-flex min-h-12 items-center gap-2 rounded-xl bg-primary px-6 font-bold text-primary-foreground shadow-sm hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-ring"
                            >
                                {text.enter}{' '}
                                <ArrowUpLeft className="size-4 ltr:rotate-180 rtl:rotate-0" />
                            </Link>
                            <Link
                                href={auth.user ? dashboard() : login()}
                                className="inline-flex min-h-12 items-center rounded-xl border bg-card px-6 font-bold shadow-sm hover:bg-muted"
                            >
                                {auth.user ? text.dashboard : text.operator}
                            </Link>
                        </div>
                    </div>
                    <aside className="rounded-3xl border bg-card/90 p-6 shadow-2xl shadow-primary/10 backdrop-blur md:p-8">
                        <div className="mb-8 flex items-center justify-between">
                            <div>
                                <p className="text-sm font-bold text-primary">
                                    SEPEHR TESTNET
                                </p>
                                <p className="mt-1 text-sm text-muted-foreground">
                                    PoW → PoS research chain
                                </p>
                            </div>
                            <span className="rounded-full bg-amber-100 px-3 py-1 text-xs font-bold text-amber-900 dark:bg-amber-400/15 dark:text-amber-200">
                                OFFLINE
                            </span>
                        </div>
                        <div className="space-y-3">
                            {text.modes.map((mode) => (
                                <div
                                    key={mode}
                                    className="flex items-center gap-3 rounded-2xl border bg-background/60 p-4"
                                >
                                    <CheckCircle2 className="size-5 shrink-0 text-primary" />
                                    <span className="font-bold">{mode}</span>
                                    <span className="ms-auto text-xs text-muted-foreground">
                                        Planned
                                    </span>
                                </div>
                            ))}
                        </div>
                        <div className="mt-6 rounded-2xl bg-muted p-5">
                            <p className="font-black">{text.privacyTitle}</p>
                            <p className="mt-2 text-sm leading-6 text-muted-foreground">
                                {text.privacyText}
                            </p>
                        </div>
                    </aside>
                </section>
            </main>
        </>
    );
}
