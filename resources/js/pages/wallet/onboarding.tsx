import { Head, Link, usePage } from '@inertiajs/react';
import {
    ArrowLeft,
    CheckCircle2,
    KeyRound,
    LoaderCircle,
    ShieldAlert,
    WalletCards,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    createLocalVoterVault,
    exportLocalVoterRecovery,
    importLocalVoterRecovery,
    LocalVoterVaultError,
    localVoterVaultExists,
    unlockLocalVoterVault,
} from '@/lib/local-voter-vault';
import { submitPublicShieldedDeposit } from '@/lib/public-shielded-deposit';
import { discovery } from '@/routes';

type Locale = 'fa' | 'en';
type VaultState =
    'checking' | 'missing' | 'locked' | 'unlocked' | 'working' | 'error';

const copy = {
    fa: {
        title: 'گاوصندوق محلی رأی‌گیر',
        eyebrow: 'پژوهش فاز چهارم',
        description:
            'یک راز تصادفی فقط در این مرورگر ساخته و با خروجی PRF کلید عبور شما رمزگذاری می‌شود.',
        create: 'ساخت گاوصندوق با کلید عبور',
        unlock: 'بازکردن با کلید عبور',
        working: 'در انتظار تأیید دستگاه…',
        ready: 'گاوصندوق محلی باز شد.',
        locked: 'گاوصندوق پیدا شد و قفل است.',
        missing: 'هنوز گاوصندوقی در این مرورگر وجود ندارد.',
        back: 'بازگشت به خانه',
        localOnly: 'فقط محلی',
        localText:
            'هیچ کلید خصوصی، شناسه کیف پول یا داده هویتی به سرور رأی‌گیر ارسال نمی‌شود.',
        limitation: 'محدودیت پژوهشی',
        limitationText:
            'این هنوز کیف پول قابل استقرار، پرداخت محرمانه یا تضمین ناشناس‌ماندن روی زنجیره نیست.',
        unsupported:
            'این مرورگر یا کلید عبور از WebAuthn PRF پشتیبانی نمی‌کند. برای امنیت، روش ضعیف‌تری جایگزین نشد.',
        cancelled: 'عملیات کلید عبور لغو شد.',
        corrupted:
            'بازکردن داده محلی ممکن نبود. داده ممکن است خراب یا متعلق به کلید عبور دیگری باشد.',
        genericError: 'ساخت یا بازکردن گاوصندوق انجام نشد.',
        exportRecovery: 'دریافت بسته بازیابی رمز‌شده',
        importRecovery: 'بازیابی از فایل',
        recoverySaved: 'بسته بازیابی روی دستگاه شما ذخیره شد.',
        depositTitle: 'واریز عمومی RAY',
        depositDescription:
            'کیف پول افزونه‌ای فقط تأیید و واریز را انجام می‌دهد. ارتباط کیف تأمین مالی با واریز روی زنجیره عمومی است؛ مصرف بعدی با یادداشت محرمانه انجام می‌شود.',
        amount: 'مقدار RAY',
        deposit: 'تأیید و واریز',
        depositing: 'در انتظار کیف پول…',
        depositQueued:
            'تراکنش واریز ارسال و یادداشت رمز‌شده روی این دستگاه ذخیره شد.',
        depositUnavailable:
            'قراردادهای واریز برای این استقرار پیکربندی نشده‌اند.',
    },
    en: {
        title: 'Raygir local voter vault',
        eyebrow: 'Phase 4 research',
        description:
            'A random secret is created only in this browser and encrypted with your passkey PRF output.',
        create: 'Create vault with passkey',
        unlock: 'Unlock with passkey',
        working: 'Waiting for device confirmation…',
        ready: 'The local vault is unlocked.',
        locked: 'A local vault exists and is locked.',
        missing: 'No local vault exists in this browser yet.',
        back: 'Back home',
        localOnly: 'Local only',
        localText:
            'No private key, wallet identifier, or identity data is sent to Raygir.',
        limitation: 'Research limitation',
        limitationText:
            'This is not yet a deployable wallet, shielded payment, or guarantee of on-chain anonymity.',
        unsupported:
            'This browser or passkey does not support WebAuthn PRF. No weaker fallback was used.',
        cancelled: 'The passkey operation was cancelled.',
        corrupted:
            'The local data could not be unlocked. It may be damaged or use another passkey.',
        genericError: 'The vault could not be created or unlocked.',
        exportRecovery: 'Download encrypted recovery package',
        importRecovery: 'Restore from file',
        recoverySaved: 'The recovery package was saved on your device.',
        depositTitle: 'Public RAY deposit',
        depositDescription:
            'Your extension wallet is used only to approve and fund this deposit. The funding-to-deposit link is public; later spending uses the private note.',
        amount: 'RAY amount',
        deposit: 'Approve and deposit',
        depositing: 'Waiting for wallet…',
        depositQueued:
            'The deposit transaction was submitted and its encrypted note was stored on this device.',
        depositUnavailable:
            'Deposit contracts are not configured for this deployment.',
    },
};

export default function WalletOnboarding() {
    const { locale } = usePage().props as unknown as { locale: Locale };
    const text = copy[locale];
    const [state, setState] = useState<VaultState>('checking');
    const [error, setError] = useState<string>();
    const [notice, setNotice] = useState<string>();
    const [amount, setAmount] = useState('');
    const [depositing, setDepositing] = useState(false);
    const tokenAddress = import.meta.env.VITE_SEPEHR_RAY_ADDRESS ?? '';
    const poolAddress = import.meta.env.VITE_SEPEHR_SHIELDED_POOL_ADDRESS ?? '';
    const depositConfigured = tokenAddress !== '' && poolAddress !== '';

    useEffect(() => {
        localVoterVaultExists()
            .then((exists) => setState(exists ? 'locked' : 'missing'))
            .catch(() => setState('error'));
    }, []);

    const handleVaultAction = async () => {
        const shouldCreate = state === 'missing' || state === 'error';
        setState('working');
        setError(undefined);

        try {
            if (shouldCreate) {
                await createLocalVoterVault();
            } else {
                await unlockLocalVoterVault();
            }

            setState('unlocked');
        } catch (caught) {
            setState(shouldCreate ? 'missing' : 'locked');
            setError(errorMessage(caught, text));
        }
    };

    const exportRecovery = async () => {
        try {
            const serialized = await exportLocalVoterRecovery();
            const download = document.createElement('a');
            download.href = URL.createObjectURL(
                new Blob([serialized], { type: 'application/json' }),
            );
            download.download = 'raygir-voter-recovery.json';
            download.click();
            URL.revokeObjectURL(download.href);
            setNotice(text.recoverySaved);
        } catch (caught) {
            setError(errorMessage(caught, text));
        }
    };

    const importRecovery = async (file?: File) => {
        if (!file) {
            return;
        }

        try {
            await importLocalVoterRecovery(await file.text());
            setState('locked');
            setError(undefined);
        } catch (caught) {
            setError(errorMessage(caught, text));
        }
    };

    const submitDeposit = async () => {
        setDepositing(true);
        setError(undefined);
        setNotice(undefined);

        try {
            await submitPublicShieldedDeposit(
                tokenAddress,
                poolAddress,
                parseDecimalUnits(amount, 18),
            );
            setAmount('');
            setNotice(text.depositQueued);
        } catch {
            setError(text.genericError);
        } finally {
            setDepositing(false);
        }
    };

    const statusText = {
        checking: text.working,
        missing: text.missing,
        locked: text.locked,
        unlocked: text.ready,
        working: text.working,
        error: text.genericError,
    }[state];

    return (
        <>
            <Head title={text.title} />
            <main className="min-h-screen bg-background px-5 py-8 text-foreground md:px-8 md:py-12">
                <div className="mx-auto max-w-5xl">
                    <Link
                        href={discovery({ locale })}
                        className="inline-flex min-h-11 items-center gap-2 rounded-xl px-3 text-sm font-bold hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring"
                    >
                        <ArrowLeft className="size-4 rtl:rotate-180" />
                        {text.back}
                    </Link>

                    <div className="mt-8 grid gap-6 lg:grid-cols-[1.1fr_.9fr]">
                        <section className="rounded-3xl border bg-card p-6 shadow-xl shadow-primary/5 md:p-10">
                            <p className="text-sm font-black text-primary">
                                {text.eyebrow}
                            </p>
                            <h1 className="mt-3 text-3xl font-black tracking-tight md:text-5xl">
                                {text.title}
                            </h1>
                            <p className="mt-5 max-w-2xl text-base leading-8 text-muted-foreground">
                                {text.description}
                            </p>

                            <div
                                className="mt-8 flex items-start gap-3 rounded-2xl border bg-background p-4"
                                role="status"
                                aria-live="polite"
                            >
                                {state === 'working' || state === 'checking' ? (
                                    <LoaderCircle className="mt-0.5 size-5 shrink-0 animate-spin text-primary motion-reduce:animate-none" />
                                ) : state === 'unlocked' ? (
                                    <CheckCircle2 className="mt-0.5 size-5 shrink-0 text-emerald-600 dark:text-emerald-400" />
                                ) : (
                                    <KeyRound className="mt-0.5 size-5 shrink-0 text-primary" />
                                )}
                                <span className="font-semibold">
                                    {statusText}
                                </span>
                            </div>

                            {error && (
                                <div
                                    className="mt-4 rounded-2xl border border-destructive/40 bg-destructive/10 p-4 text-sm leading-6 text-destructive"
                                    role="alert"
                                >
                                    {error}
                                </div>
                            )}

                            {notice && (
                                <p className="mt-4 text-sm font-semibold text-emerald-700 dark:text-emerald-300">
                                    {notice}
                                </p>
                            )}

                            {state !== 'checking' && state !== 'unlocked' && (
                                <Button
                                    type="button"
                                    size="lg"
                                    className="mt-6 min-h-12 rounded-xl px-6 font-bold"
                                    disabled={state === 'working'}
                                    onClick={handleVaultAction}
                                >
                                    {state === 'working' && (
                                        <LoaderCircle className="animate-spin" />
                                    )}
                                    {state === 'working'
                                        ? text.working
                                        : state === 'missing' ||
                                            state === 'error'
                                          ? text.create
                                          : text.unlock}
                                </Button>
                            )}

                            <div className="mt-4 flex flex-wrap gap-3">
                                {state === 'unlocked' && (
                                    <Button
                                        type="button"
                                        variant="outline"
                                        onClick={exportRecovery}
                                    >
                                        {text.exportRecovery}
                                    </Button>
                                )}
                                <label className="inline-flex min-h-10 cursor-pointer items-center rounded-md border px-4 py-2 text-sm font-medium focus-within:ring-2 focus-within:ring-ring hover:bg-muted">
                                    {text.importRecovery}
                                    <input
                                        type="file"
                                        accept="application/json,.json"
                                        className="sr-only"
                                        onChange={(event) =>
                                            importRecovery(
                                                event.target.files?.[0],
                                            )
                                        }
                                    />
                                </label>
                            </div>
                        </section>

                        {state === 'unlocked' && (
                            <section className="rounded-3xl border bg-card p-6 shadow-xl shadow-primary/5 md:p-10 lg:col-span-2">
                                <div className="flex items-start gap-3">
                                    <WalletCards className="mt-1 size-6 shrink-0 text-primary" />
                                    <div>
                                        <h2 className="text-xl font-black">
                                            {text.depositTitle}
                                        </h2>
                                        <p className="mt-2 max-w-3xl text-sm leading-7 text-muted-foreground">
                                            {text.depositDescription}
                                        </p>
                                    </div>
                                </div>

                                {depositConfigured ? (
                                    <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-end">
                                        <label className="grid flex-1 gap-2 text-sm font-bold">
                                            {text.amount}
                                            <Input
                                                inputMode="decimal"
                                                value={amount}
                                                onChange={(event) =>
                                                    setAmount(
                                                        event.target.value,
                                                    )
                                                }
                                                placeholder="0.0"
                                                disabled={depositing}
                                            />
                                        </label>
                                        <Button
                                            type="button"
                                            className="min-h-10"
                                            disabled={
                                                depositing || amount === ''
                                            }
                                            onClick={submitDeposit}
                                        >
                                            {depositing && (
                                                <LoaderCircle className="animate-spin motion-reduce:animate-none" />
                                            )}
                                            {depositing
                                                ? text.depositing
                                                : text.deposit}
                                        </Button>
                                    </div>
                                ) : (
                                    <p className="mt-6 rounded-2xl border border-amber-400/40 bg-amber-100/60 p-4 text-sm text-amber-950 dark:bg-amber-400/10 dark:text-amber-100">
                                        {text.depositUnavailable}
                                    </p>
                                )}
                            </section>
                        )}

                        <aside className="grid content-start gap-4">
                            <InfoCard
                                icon={<KeyRound className="size-5" />}
                                title={text.localOnly}
                                body={text.localText}
                            />
                            <InfoCard
                                icon={<ShieldAlert className="size-5" />}
                                title={text.limitation}
                                body={text.limitationText}
                                warning
                            />
                        </aside>
                    </div>
                </div>
            </main>
        </>
    );
}

function parseDecimalUnits(value: string, decimals: number): bigint {
    if (!/^\d+(\.\d+)?$/u.test(value)) {
        throw new Error('invalid-amount');
    }

    const [whole, fraction = ''] = value.split('.');

    if (fraction.length > decimals) {
        throw new Error('invalid-amount');
    }

    return (
        BigInt(whole) * 10n ** BigInt(decimals) +
        BigInt(fraction.padEnd(decimals, '0'))
    );
}

function InfoCard({
    icon,
    title,
    body,
    warning = false,
}: {
    icon: ReactNode;
    title: string;
    body: string;
    warning?: boolean;
}) {
    return (
        <div
            className={
                warning
                    ? 'rounded-3xl border border-amber-400/40 bg-amber-100/60 p-6 text-amber-950 dark:bg-amber-400/10 dark:text-amber-100'
                    : 'rounded-3xl border bg-card p-6'
            }
        >
            <div className="flex items-center gap-3 font-black">
                {icon}
                {title}
            </div>
            <p className="mt-3 text-sm leading-7 opacity-80">{body}</p>
        </div>
    );
}

function errorMessage(error: unknown, text: (typeof copy)[Locale]): string {
    if (!(error instanceof LocalVoterVaultError)) {
        return text.genericError;
    }

    switch (error.code) {
        case 'unsupported':
        case 'prf-unsupported':
            return text.unsupported;
        case 'cancelled':
            return text.cancelled;
        case 'corrupted':
            return text.corrupted;
        default:
            return text.genericError;
    }
}
