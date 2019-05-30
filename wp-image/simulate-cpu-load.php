<?php
/**
 * Simulate CPU load
 *
 * Used for testing Horizontal Pod Autoscaler
 * Making calculations when hitting this uri
 *
 * Returns valid JSON with code 200
 *
 */

for($i = 0; $i < 10000000; $i++) {
     $num += $i;
};

echo sprintf('{"num": %d}', $num);
