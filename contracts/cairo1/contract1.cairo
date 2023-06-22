#[contract]
mod Contract {

    struct Storage {
        balance: felt252,
    }

    #[constructor]
    fn constructor(initial_balance: felt252) {
        balance::write(initial_balance);
    }

}