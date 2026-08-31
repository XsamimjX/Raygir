<?php

namespace App\Services\Clob;

use App\Contracts\ClobBatchProver;
use RuntimeException;
use Symfony\Component\Process\Process;

class CommandClobBatchProver implements ClobBatchProver
{
    public function prove(array $witness): array
    {
        $command = config('services.clob.prover_command');
        if (! is_string($command) || $command === '') {
            throw new RuntimeException('CLOB_PROVER_COMMAND is not configured.');
        }

        $process = new Process([$command]);
        $process->setInput(json_encode($witness, JSON_THROW_ON_ERROR));
        $process->setTimeout((float) config('services.clob.prover_timeout', 120));
        $process->mustRun();
        $result = json_decode($process->getOutput(), true, flags: JSON_THROW_ON_ERROR);
        if (! is_array($result)
            || ! is_string($result['proof'] ?? null)
            || ! is_array($result['public_inputs'] ?? null)
            || ! is_string($result['next_root'] ?? null)
            || preg_match('/\A[0-9a-f]{64}\z/', $result['next_root']) !== 1
            || array_any($result['public_inputs'], fn (mixed $input): bool => ! is_string($input))) {
            throw new RuntimeException('CLOB prover returned an invalid response.');
        }

        return [
            'proof' => $result['proof'],
            'public_inputs' => array_values($result['public_inputs']),
            'next_root' => $result['next_root'],
        ];
    }
}
