<?php

namespace App\Contracts;

interface ClobBatchProver
{
    /** @param array<string, mixed> $witness @return array{proof: string, public_inputs: array<int, string>, next_root: string} */
    public function prove(array $witness): array;
}
