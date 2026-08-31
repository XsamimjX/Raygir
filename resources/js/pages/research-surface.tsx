import { Head, Link, usePage } from '@inertiajs/react';
import {
    AlertTriangle,
    ArrowLeft,
    BarChart3,
    FileCheck2,
    Flag,
    Landmark,
    LockKeyhole,
    RefreshCcw,
    Scale,
    ShieldCheck,
    WalletCards,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import PublicLayout from '@/layouts/public-layout';
import { markets } from '@/routes';

type Locale = 'fa' | 'en';
type Surface =
    | 'civic'
    | 'prediction'
    | 'exchange'
    | 'create'
    | 'portfolio'
    | 'reports'
    | 'evidence'
    | 'challenges'
    | 'refunds';

type SurfaceCopy = {
    title: string;
    description: string;
    disclosure: string;
    sections: string[];
};

const icons: Record<Surface, LucideIcon> = {
    civic: Landmark,
    prediction: BarChart3,
    exchange: LockKeyhole,
    create: FileCheck2,
    portfolio: WalletCards,
    reports: Flag,
    evidence: ShieldCheck,
    challenges: Scale,
    refunds: RefreshCcw,
};

const copy: Record<
    Locale,
    { common: Record<string, string>; surfaces: Record<Surface, SurfaceCopy> }
> = {
    fa: {
        common: {
            eyebrow: 'رأی‌گیر · شبکه پژوهشی',
            unavailable: 'داده زنجیره‌ای هنوز در دسترس نیست',
            empty: 'پس از ثبت داده واقعی و تأییدشده، این بخش به‌روز می‌شود. هیچ داده نمایشی ساخته نشده است.',
            back: 'بازگشت به بازارها',
            privacy: 'مرز حریم خصوصی',
            status: 'وضعیت فعلی',
            testnet: 'دارایی‌های آزمایشی ارزش مالی یا حق بازخرید ندارند.',
        },
        surfaces: {
            civic: {
                title: 'نظرسنجی مدنی',
                description:
                    'قواعد واجدشرایط‌بودن، اعتبارها، زمان‌بندی و نتیجه‌های ناشناس.',
                disclosure:
                    'هویت و کیف تأمین مالی پنهان می‌ماند؛ انتخاب ناشناس پس از بسته‌شدن عمومی می‌شود.',
                sections: [
                    'اثبات واجدشرایط‌بودن',
                    'تخصیص اعتبار',
                    'رسید و یادآوری افشا',
                    'نتیجه و دور دوم',
                ],
            },
            prediction: {
                title: 'استخر پیش‌بینی',
                description: 'سهم‌گذاری خصوصی RAY و تسویه پاری‌موتوئل.',
                disclosure:
                    'سازنده ۱۰٪ کل استخر را می‌گیرد؛ حتی برنده ممکن است کمتر از اصل سهم خود دریافت کند.',
                sections: [
                    'ترکیب استخر',
                    'برگه سهم‌گذاری',
                    'شواهد و پیشنهاد نتیجه',
                    'مطالبه یا بازپرداخت',
                ],
            },
            exchange: {
                title: 'بازار دفتر سفارش',
                description: 'موقعیت‌های کاملاً وثیقه‌شده با تطبیق قیمت-زمان.',
                disclosure:
                    'تطبیق‌گر قیمت و اندازه سفارش را می‌بیند، اما نباید هویت واقعی یا کیف تأمین مالی را دریافت کند.',
                sections: [
                    'عمق تجمیعی بازار',
                    'برگه سفارش',
                    'سفارش‌ها و موقعیت‌های خصوصی',
                    'تفکیک، ادغام و بازخرید',
                ],
            },
            create: {
                title: 'ساخت نظرسنجی یا بازار',
                description:
                    'پیش‌نویس محلی، مانیفست تغییرناپذیر و بررسی ساختاریافته.',
                disclosure:
                    'متن عمومی برای بررسی ارسال می‌شود؛ رأی دولتی فقط با مانیفست امضاشده مرجع ساخته می‌شود.',
                sections: [
                    'نوع و متن دوزبانه',
                    'واجدشرایط‌بودن و زمان',
                    'شواهد و اقتصاد',
                    'بررسی، کارمزد و بازپرداخت',
                ],
            },
            portfolio: {
                title: 'سبد خصوصی و تأمین مالی',
                description:
                    'جداسازی واریز عمومی از یادداشت‌ها و موقعیت‌های خصوصی.',
                disclosure:
                    'واریز روی زنجیره عمومی است. زمان‌بندی، دستگاه و فراداده شبکه می‌توانند اطلاعات جانبی آشکار کنند.',
                sections: [
                    'اعتبارهای مدنی',
                    'موقعیت‌های استخر',
                    'سفارش‌ها و وثیقه',
                    'بازیابی رمزگذاری‌شده',
                ],
            },
            reports: {
                title: 'گزارش تخلف',
                description:
                    'یک گزارش ناشناس برای هر اعتبار واجدشرایط و هر نظرسنجی.',
                disclosure:
                    'شناسه تهی‌ساز مانع گزارش تکراری می‌شود؛ هویت گزارشگر نباید ذخیره شود.',
                sections: [
                    'دلیل گزارش',
                    'پیشرفت آستانه',
                    'وضعیت توقف',
                    'تصمیم قابل ممیزی',
                ],
            },
            evidence: {
                title: 'شواهد و پیشنهاد نتیجه',
                description: 'منبع، زمان دریافت، هش محتوا و تاریخچه اصلاح.',
                disclosure:
                    'هوش مصنوعی فقط پیشنهاد می‌دهد و به‌تنهایی اجازه تسویه دارایی را ندارد.',
                sections: [
                    'منابع مجاز',
                    'شواهد بازیابی‌شده',
                    'امضاهای کمیته',
                    'مهلت حل‌وفصل',
                ],
            },
            challenges: {
                title: 'اعتراض به نتیجه',
                description: 'وثیقه، مهلت، وضعیت کمیته و استدلال منتشرشده.',
                disclosure:
                    'عدم رسیدن به نصاب ظرف هفت روز بازار را نامعتبر و سهم‌ها را قابل بازپرداخت می‌کند.',
                sections: [
                    'وثیقه اعتراض',
                    'مهلت ۴۸ ساعته',
                    'بررسی کمیته',
                    'پیامد بازپرداخت',
                ],
            },
            refunds: {
                title: 'بازپرداخت‌ها',
                description:
                    'مطالبه گروهی و سابقه ممیزی برای بازارهای نامعتبر.',
                disclosure:
                    'بازار نامعتبر، بی‌نتیجه یا منقضی همه سهم‌ها را بازمی‌گرداند و پاداش سازنده ندارد.',
                sections: [
                    'مبلغ قابل بازپرداخت',
                    'نوع مقصد',
                    'زمان واجدشرایط‌شدن',
                    'وضعیت مطالبه',
                ],
            },
        },
    },
    en: {
        common: {
            eyebrow: 'Raygir · research network',
            unavailable: 'Chain data is not available yet',
            empty: 'This area updates when verified real data exists. No demonstration records have been invented.',
            back: 'Back to markets',
            privacy: 'Privacy boundary',
            status: 'Current state',
            testnet: 'Test assets have no monetary value or redemption right.',
        },
        surfaces: {
            civic: {
                title: 'Civic poll',
                description:
                    'Eligibility rules, credits, timing, and anonymous results.',
                disclosure:
                    'Identity and funding wallet remain hidden; the anonymous choice becomes public after closing.',
                sections: [
                    'Eligibility proof',
                    'Credit allocation',
                    'Receipt and reveal reminder',
                    'Results and runoff',
                ],
            },
            prediction: {
                title: 'Prediction pool',
                description: 'Private RAY staking with pari-mutuel settlement.',
                disclosure:
                    'The creator receives 10% of the whole pot; even a winner may receive less than their principal.',
                sections: [
                    'Pool composition',
                    'Stake ticket',
                    'Evidence and outcome proposal',
                    'Claim or refund',
                ],
            },
            exchange: {
                title: 'Order-book market',
                description:
                    'Fully collateralized positions with price-time matching.',
                disclosure:
                    'The matcher sees order price and size, but must not receive real identity or funding-wallet data.',
                sections: [
                    'Aggregate market depth',
                    'Order ticket',
                    'Private orders and positions',
                    'Split, merge, and redeem',
                ],
            },
            create: {
                title: 'Create a poll or market',
                description:
                    'Local draft, immutable manifest, and structured review.',
                disclosure:
                    'Public wording is reviewed. Government ballots require an authority-signed manifest and cannot be created here.',
                sections: [
                    'Type and bilingual wording',
                    'Eligibility and timing',
                    'Evidence and economics',
                    'Review, fee, and refund',
                ],
            },
            portfolio: {
                title: 'Private portfolio and funding',
                description:
                    'Public deposits are separated from private notes and positions.',
                disclosure:
                    'Deposits are public on-chain. Timing, device, and network metadata may still leak information.',
                sections: [
                    'Civic receipts',
                    'Pool positions',
                    'Orders and collateral',
                    'Encrypted recovery',
                ],
            },
            reports: {
                title: 'Report a violation',
                description:
                    'One anonymous report per eligible credential and poll.',
                disclosure:
                    'A nullifier prevents duplicate reports; reporter identity must not be stored.',
                sections: [
                    'Report reason',
                    'Threshold progress',
                    'Pause state',
                    'Auditable decision',
                ],
            },
            evidence: {
                title: 'Evidence and outcome proposal',
                description:
                    'Source, retrieval time, content hash, and correction history.',
                disclosure:
                    'AI proposes only. It can never settle assets without the resolver committee.',
                sections: [
                    'Allowed sources',
                    'Retrieved evidence',
                    'Committee signatures',
                    'Resolution deadline',
                ],
            },
            challenges: {
                title: 'Challenge an outcome',
                description:
                    'Bond, deadline, committee state, and published reasoning.',
                disclosure:
                    'No quorum within seven days invalidates the market and makes stakes refundable.',
                sections: [
                    'Challenge bond',
                    '48-hour deadline',
                    'Committee review',
                    'Refund consequence',
                ],
            },
            refunds: {
                title: 'Refunds',
                description:
                    'Batch claims and per-market audit trails for invalid markets.',
                disclosure:
                    'Invalid, unresolved, timed-out, or no-winner markets return all stakes and pay no creator reward.',
                sections: [
                    'Refundable amount',
                    'Destination type',
                    'Eligibility time',
                    'Claim state',
                ],
            },
        },
    },
};

export default function ResearchSurface({ surface }: { surface: Surface }) {
    const { locale } = usePage().props as unknown as { locale: Locale };
    const text = copy[locale];
    const page = text.surfaces[surface];
    const Icon = icons[surface];

    return (
        <PublicLayout>
            <Head title={page.title} />
            <section className="mx-auto max-w-7xl px-4 py-10 md:px-8 md:py-16">
                <Link
                    href={markets({ locale })}
                    className="inline-flex min-h-11 items-center gap-2 rounded-xl px-3 font-bold hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring"
                >
                    <ArrowLeft
                        className="size-4 rtl:rotate-180"
                        aria-hidden="true"
                    />{' '}
                    {text.common.back}
                </Link>
                <div className="mt-8 grid gap-8 lg:grid-cols-[1.2fr_.8fr]">
                    <div>
                        <p className="flex items-center gap-2 text-sm font-black tracking-wider text-primary uppercase">
                            <Icon className="size-5" aria-hidden="true" />
                            {text.common.eyebrow}
                        </p>
                        <h1 className="mt-4 text-4xl font-black tracking-tight md:text-6xl">
                            {page.title}
                        </h1>
                        <p className="mt-5 max-w-3xl text-lg leading-8 text-muted-foreground">
                            {page.description}
                        </p>
                    </div>
                    <aside className="rounded-3xl border border-amber-500/30 bg-amber-500/10 p-6">
                        <h2 className="flex items-center gap-2 font-black">
                            <AlertTriangle
                                className="size-5"
                                aria-hidden="true"
                            />
                            {text.common.privacy}
                        </h2>
                        <p className="mt-3 leading-7">{page.disclosure}</p>
                        <p className="mt-4 border-t border-amber-500/25 pt-4 text-sm font-bold">
                            {text.common.testnet}
                        </p>
                    </aside>
                </div>
                <div className="mt-10 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    {page.sections.map((section) => (
                        <section
                            key={section}
                            className="rounded-2xl border bg-card p-5 shadow-sm"
                        >
                            <h2 className="font-black">{section}</h2>
                            <p className="mt-3 text-sm leading-6 text-muted-foreground">
                                {text.common.empty}
                            </p>
                        </section>
                    ))}
                </div>
                <section
                    className="mt-8 rounded-3xl border border-dashed bg-muted/35 p-8 text-center"
                    aria-live="polite"
                >
                    <h2 className="text-xl font-black">{text.common.status}</h2>
                    <p className="mt-2 text-muted-foreground">
                        {text.common.unavailable}
                    </p>
                </section>
            </section>
        </PublicLayout>
    );
}
