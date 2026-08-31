import { Head, Link } from '@inertiajs/react';
import {
    ArrowUpLeft,
    BarChart3,
    Landmark,
    LockKeyhole,
    Search,
} from 'lucide-react';
import PublicLayout from '@/layouts/public-layout';
import { civic, exchange, prediction } from '@/routes/raygir';
import { onboarding } from '@/routes/wallet';

type Locale = 'fa' | 'en';

const copy = {
    fa: {
        title: 'بازارها و رأی‌گیری‌ها',
        description:
            'نظرسنجی مدنی، استخر پیش‌بینی و دفتر سفارش پیوسته را بدون داده نمایشی جست‌وجو کنید.',
        search: 'جست‌وجو در پرسش‌ها',
        emptyTitle: 'هنوز بازار عمومی وجود ندارد',
        emptyText:
            'پس از انتشار نخستین بازار تأییدشده، اطلاعات واقعی زنجیره در این صفحه نمایش داده می‌شود.',
        start: 'ساخت گاوصندوق محلی',
        modes: [
            [
                'نظرسنجی مدنی',
                'اعتبار واجدشرایط؛ بدون خرید قدرت رأی',
                'پس از بسته‌شدن، انتخاب‌های ناشناس عمومی می‌شوند.',
            ],
            [
                'استخر پیش‌بینی',
                'سهم‌گذاری خصوصی RAY و تسویه پاری‌موتوئل',
                'خالق ۱۰٪ کل استخر را دریافت می‌کند؛ اصل سهم تضمین نیست.',
            ],
            [
                'بازار سفارش',
                'موقعیت‌های کاملاً وثیقه‌شده و تطبیق قیمت-زمان',
                'تطبیق‌گر سفارش را می‌بیند، اما هویت واقعی یا کیف تأمین مالی را دریافت نمی‌کند.',
            ],
        ],
    },
    en: {
        title: 'Markets and polls',
        description:
            'Explore civic polls, prediction pools, and continuous order books without fabricated data.',
        search: 'Search questions',
        emptyTitle: 'No public markets yet',
        emptyText:
            'Real chain-derived data will appear here after the first approved market is published.',
        start: 'Create local vault',
        modes: [
            [
                'Civic poll',
                'Eligibility credits; voting power cannot be purchased',
                'Anonymous choices become public after closing.',
            ],
            [
                'Prediction pool',
                'Private RAY stakes with pari-mutuel settlement',
                'The creator receives 10% of the whole pot; principal is not guaranteed.',
            ],
            [
                'Order-book market',
                'Fully collateralized positions with price-time matching',
                'The matcher sees orders but receives no real identity or funding wallet.',
            ],
        ],
    },
};

const icons = [Landmark, BarChart3, LockKeyhole];
const destinations = [civic, prediction, exchange];

export default function MarketsIndex({ locale }: { locale: Locale }) {
    const text = copy[locale];

    return (
        <PublicLayout>
            <Head title={text.title} />
            <section className="mx-auto max-w-7xl px-4 py-10 md:px-8 md:py-16">
                <div className="max-w-3xl">
                    <p className="text-sm font-black tracking-widest text-primary uppercase">
                        Raygir Testnet
                    </p>
                    <h1 className="mt-3 text-4xl font-black tracking-tight md:text-6xl">
                        {text.title}
                    </h1>
                    <p className="mt-5 text-lg leading-8 text-muted-foreground">
                        {text.description}
                    </p>
                </div>

                <label className="mt-8 flex min-h-12 max-w-2xl items-center gap-3 rounded-2xl border bg-card px-4 shadow-sm focus-within:ring-2 focus-within:ring-ring">
                    <Search
                        className="size-5 text-muted-foreground"
                        aria-hidden="true"
                    />
                    <span className="sr-only">{text.search}</span>
                    <input
                        type="search"
                        placeholder={text.search}
                        disabled
                        className="min-w-0 flex-1 bg-transparent outline-none disabled:cursor-not-allowed"
                    />
                </label>

                <div className="mt-10 grid gap-4 md:grid-cols-3">
                    {text.modes.map(
                        ([title, description, disclosure], index) => {
                            const Icon = icons[index];

                            return (
                                <article
                                    key={title}
                                    className="rounded-3xl border bg-card p-6 shadow-sm"
                                >
                                    <Icon
                                        className="size-7 text-primary"
                                        aria-hidden="true"
                                    />
                                    <h2 className="mt-5 text-xl font-black">
                                        <Link
                                            href={destinations[index]({
                                                locale,
                                            })}
                                            className="rounded-md focus-visible:ring-2 focus-visible:ring-ring"
                                        >
                                            {title}
                                        </Link>
                                    </h2>
                                    <p className="mt-2 text-sm leading-6 text-muted-foreground">
                                        {description}
                                    </p>
                                    <p className="mt-5 border-t pt-4 text-xs leading-5 text-amber-800 dark:text-amber-200">
                                        {disclosure}
                                    </p>
                                </article>
                            );
                        },
                    )}
                </div>

                <section
                    className="mt-10 rounded-3xl border border-dashed bg-muted/35 px-6 py-14 text-center"
                    aria-live="polite"
                >
                    <h2 className="text-2xl font-black">{text.emptyTitle}</h2>
                    <p className="mx-auto mt-3 max-w-xl leading-7 text-muted-foreground">
                        {text.emptyText}
                    </p>
                    <Link
                        href={onboarding({ locale })}
                        className="mt-7 inline-flex min-h-12 items-center gap-2 rounded-xl bg-primary px-5 font-bold text-primary-foreground focus-visible:ring-2 focus-visible:ring-ring"
                    >
                        {text.start}
                        <ArrowUpLeft
                            className="size-4 ltr:rotate-180"
                            aria-hidden="true"
                        />
                    </Link>
                </section>
            </section>
        </PublicLayout>
    );
}
