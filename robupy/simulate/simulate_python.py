# standard library
import pandas as pd
import numpy as np
import logging

# project library

from robupy.shared.constants import MISSING_FLOAT
from robupy.shared.auxiliary import get_total_value

logger = logging.getLogger('ROBUPY_SIMULATE')


''' Main function
'''
def pyth_simulate(periods_payoffs_systematic, mapping_state_idx,
        periods_emax, num_periods, states_all, num_agents, edu_start,
        edu_max, delta, periods_draws_sims):
    """ Wrapper for PYTHON and F2PY implementation of sample simulation.
    """
    count = 0

    # Initialize data
    dataset = np.tile(MISSING_FLOAT, (num_agents * num_periods, 8))

    for i in range(num_agents):

        current_state = states_all[0, 0, :].copy()

        dataset[count, 0] = i

        # Logging
        if (i != 0) and (i % 100 == 0):
            logger.info('... simulated ' + str(i) + ' agents')

        # Iterate over each period for the agent
        for period in range(num_periods):

            # Distribute state space
            exp_a, exp_b, edu, edu_lagged = current_state

            k = mapping_state_idx[period, exp_a, exp_b, edu, edu_lagged]

            # Write agent identifier and current period to data frame
            dataset[count, :2] = i, period

            # Select relevant subset
            payoffs_systematic = periods_payoffs_systematic[period, k, :]
            draws = periods_draws_sims[period, i, :]

            # Get total value of admissible states
            total_payoffs = get_total_value(period,
                num_periods, delta, payoffs_systematic, draws, edu_max,
                edu_start, mapping_state_idx, periods_emax, k, states_all)

            # Determine optimal choice
            max_idx = np.argmax(total_payoffs)

            # Record agent decision
            dataset[count, 2] = max_idx + 1

            # Record earnings
            dataset[count, 3] = MISSING_FLOAT
            if max_idx in [0, 1]:
                dataset[count, 3] = payoffs_systematic[max_idx] * draws[max_idx]

            # Write relevant state space for period to data frame
            dataset[count, 4:8] = current_state

            # Special treatment for education
            dataset[count, 6] += edu_start

            # Update work experiences and education
            if max_idx == 0:
                current_state[0] += 1
            elif max_idx == 1:
                current_state[1] += 1
            elif max_idx == 2:
                current_state[2] += 1

            # Update lagged education
            current_state[3] = 0

            if max_idx == 2:
                current_state[3] = 1

            # Update row indicator
            count += 1

    # Finishing
    return dataset
