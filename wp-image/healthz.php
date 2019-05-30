<?php
/**
 * Health endpoint
 *
 * Used for Readiness and Liveness probes
 *
 * Returns valid JSON with code 200
 *
 */

echo '{"health": "OK"}';
