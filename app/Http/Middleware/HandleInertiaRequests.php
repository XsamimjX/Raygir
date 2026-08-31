<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    /**
     * The root template that's loaded on the first page visit.
     *
     * @see https://inertiajs.com/server-side-setup#root-template
     *
     * @var string
     */
    protected $rootView = 'app';

    /**
     * Determines the current asset version.
     *
     * @see https://inertiajs.com/asset-versioning
     */
    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    /**
     * Define the props that are shared by default.
     *
     * @see https://inertiajs.com/shared-data
     *
     * @return array<string, mixed>
     */
    public function share(Request $request): array
    {
        $locale = $request->route('locale');
        $locale = is_string($locale) && in_array($locale, ['fa', 'en'], true)
            ? $locale
            : app()->getLocale();
        $isAnonymousVoterRoute = $request->routeIs('discovery', 'markets', 'wallet.*', 'raygir.*');

        return [
            ...parent::share($request),
            'name' => config('app.name'),
            'locale' => $locale,
            'direction' => $locale === 'fa' ? 'rtl' : 'ltr',
            'auth' => [
                'user' => $isAnonymousVoterRoute ? null : $request->user(),
            ],
            'sidebarOpen' => ! $request->hasCookie('sidebar_state') || $request->cookie('sidebar_state') === 'true',
        ];
    }
}
