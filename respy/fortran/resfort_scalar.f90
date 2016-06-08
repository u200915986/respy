!*****************************************************************************
!***************************************************************************** 
PROGRAM resfort_scalar

    !/* external modules        */

    USE resfort_library

    !/* setup                   */

    IMPLICIT NONE

    !/* objects                 */

    REAL(our_dble)                  :: shocks_cholesky(4, 4)
    REAL(our_dble)                  :: coeffs_home(1)
    REAL(our_dble)                  :: coeffs_edu(3)
    REAL(our_dble)                  :: coeffs_a(6)
    REAL(our_dble)                  :: coeffs_b(6)
    REAL(our_dble)                  :: x_start(26)
    REAL(our_dble)                  :: x_final(26)
    REAL(our_dble)                  :: crit_val

    REAL(our_dble), ALLOCATABLE     :: periods_draws_sims(:, :, :)
    REAL(our_dble), ALLOCATABLE     :: data_sim(:, :)

    INTEGER(our_int)   :: iter

    INTEGER(our_int)     :: maxfun
    INTEGER(our_int)    :: npt
    
    REAL(our_dble)      :: rhobeg
    REAL(our_dble)  :: rhoend

    LOGICAL      :: success

    CHARACTER(150)                  :: message



!------------------------------------------------------------------------------
! Algorithm
!------------------------------------------------------------------------------


    CALL read_specification(coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cholesky)

    CALL create_draws(periods_draws_emax, num_draws_emax, seed_emax)

    ALLOCATE(data_sim(num_periods * num_agents_sim, 8))


    IF (request == 'solve') THEN

        CALL fort_solve(periods_payoffs_systematic, states_number_period, mapping_state_idx, periods_emax, states_all, coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cholesky, periods_draws_emax)

    ELSE IF (request == 'estimate') THEN

        CALL create_draws(periods_draws_prob, num_draws_prob, seed_prob)

        CALL read_dataset(data_est, num_agents_est)

        CALL get_optim_paras(x_start, coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cholesky)


        crit_val = fort_criterion(x_start)
        PRINT *, 'I am estimating :) '

        npt =  min(26 * 2, 26 + 2)

        rhobeg = 0.1
        rhoend = 1e-6 * rhobeg
        maxfun = 20


        PRINT *, 'START ', x_start(:3)

        x_final = x_start

        CALL NEWUOA (fort_criterion, x_final, npt, rhobeg, rhoend, zero_int, maxfun, success, message, iter)


        PRINT *, 'Final ', x_start(:3)


  ELSE IF (request == 'simulate') THEN

        CALL create_draws(periods_draws_sims, num_agents_sim, seed_sim)

        CALL fort_solve(periods_payoffs_systematic, states_number_period, mapping_state_idx, periods_emax, states_all, coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cholesky, periods_draws_emax)

        CALL fort_simulate(data_sim, periods_payoffs_systematic, mapping_state_idx, periods_emax, states_all, num_agents_sim, periods_draws_sims, shocks_cholesky)

    END IF


    CALL store_results(mapping_state_idx, states_all, periods_payoffs_systematic, states_number_period, periods_emax, crit_val, data_sim)

!******************************************************************************
!******************************************************************************
END PROGRAM