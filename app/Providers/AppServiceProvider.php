<?php

namespace App\Providers;

use App\Contracts\ClobBatchProver;
use App\Contracts\ClobSettlementGateway;
use App\Contracts\PublicContentReviewer;
use App\Services\Clob\CommandClobBatchProver;
use App\Services\Clob\HttpClobSettlementGateway;
use App\Services\Moderation\HttpPublicContentReviewer;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\ServiceProvider;
use Illuminate\Validation\Rules\Password;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(PublicContentReviewer::class, HttpPublicContentReviewer::class);
        $this->app->bind(ClobBatchProver::class, CommandClobBatchProver::class);
        $this->app->bind(ClobSettlementGateway::class, HttpClobSettlementGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureDefaults();
    }

    /**
     * Configure default behaviors for production-ready applications.
     */
    protected function configureDefaults(): void
    {
        Date::use(CarbonImmutable::class);

        DB::prohibitDestructiveCommands(
            app()->isProduction(),
        );

        Password::defaults(fn (): ?Password => app()->isProduction()
            ? Password::min(12)
                ->mixedCase()
                ->letters()
                ->numbers()
                ->symbols()
                ->uncompromised()
            : null,
        );
    }
}
