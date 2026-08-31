import { Link, usePage } from '@inertiajs/react';
import { Globe2, ShieldCheck } from 'lucide-react';
import type { PropsWithChildren } from 'react';
import { discovery, markets } from '@/routes';
import { onboarding } from '@/routes/wallet';

type Locale = 'fa' | 'en';

const copy = {
    fa: {
        discovery: 'کشف بازارها',
        wallet: 'گاوصندوق من',
        research: 'شبکه پژوهشی؛ دارایی‌ها ارزش مالی ندارند',
        language: 'English',
    },
    en: {
        discovery: 'Discover',
        wallet: 'My vault',
        research: 'Research network; assets have no monetary value',
        language: 'فارسی',
    },
};

export default function PublicLayout({ children }: PropsWithChildren) {
    const { locale } = usePage().props as unknown as { locale: Locale };
    const text = copy[locale];
    const alternateLocale: Locale = locale === 'fa' ? 'en' : 'fa';

    return (
        <div className="min-h-screen bg-background text-foreground">
            <a
                href="#main-content"
                className="sr-only z-50 rounded-md bg-background px-4 py-2 focus:not-sr-only focus:fixed focus:start-4 focus:top-4"
            >
                {locale === 'fa'
                    ? 'رفتن به محتوای اصلی'
                    : 'Skip to main content'}
            </a>
            <div className="border-b border-amber-500/25 bg-amber-500/10 px-4 py-2 text-center text-xs font-bold text-amber-900 dark:text-amber-100">
                <ShieldCheck
                    className="me-1 inline size-4"
                    aria-hidden="true"
                />
                {text.research}
            </div>
            <header className="sticky top-0 z-40 border-b bg-background/90 backdrop-blur">
                <nav
                    className="mx-auto flex min-h-16 max-w-7xl items-center gap-3 px-4 md:px-8"
                    aria-label={
                        locale === 'fa' ? 'ناوبری اصلی' : 'Primary navigation'
                    }
                >
                    <Link
                        href={discovery({ locale })}
                        className="flex items-center gap-2 font-black"
                    >
                        <span className="grid size-9 place-items-center rounded-xl bg-primary text-primary-foreground">
                            ر
                        </span>
                        <span>Raygir</span>
                    </Link>
                    <div className="ms-auto flex items-center gap-1 sm:gap-2">
                        <Link
                            href={markets({ locale })}
                            className="inline-flex min-h-11 items-center rounded-xl px-3 text-sm font-bold hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring"
                        >
                            {text.discovery}
                        </Link>
                        <Link
                            href={onboarding({ locale })}
                            className="hidden min-h-11 items-center rounded-xl border bg-card px-3 text-sm font-bold hover:bg-muted sm:inline-flex"
                        >
                            {text.wallet}
                        </Link>
                        <Link
                            href={markets({ locale: alternateLocale })}
                            className="inline-flex min-h-11 items-center gap-2 rounded-xl px-3 text-sm font-bold hover:bg-muted"
                        >
                            <Globe2 className="size-4" aria-hidden="true" />
                            <span className="hidden sm:inline">
                                {text.language}
                            </span>
                        </Link>
                    </div>
                </nav>
            </header>
            <main id="main-content">{children}</main>
        </div>
    );
}
