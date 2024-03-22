module kriya_lp_vault::kriya_vsui_lp {

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui::transfer;
    use kriya::spot_dex::{Self, KriyaLPToken};
    use volo_sui::cert::CERT;

    struct KRIYA_VSUI_LP has drop {}

    struct KriyaLpVault has key {
        id: UID,
        lp_token: KriyaLPToken<CERT, SUI>,
        treasury_cap: TreasuryCap<KRIYA_VSUI_LP>,
    }

    fun init(otw: KRIYA_VSUI_LP, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            9,
            b"KVLP",
            b"KRIYA-VSUI-LP",
            b"Fungible token of vSUI/SUI LP on KriyaDEX",
            std::option::none(),
            ctx,
        );
        let deployer = tx_context::sender(ctx);
        transfer::public_transfer(treasury_cap, deployer);
        transfer::public_transfer(metadata, deployer);
    }

    public fun init_vault(
        treasury_cap: TreasuryCap<KRIYA_VSUI_LP>,
        lp_token: KriyaLPToken<CERT, SUI>,
        ctx: &mut TxContext,
    ) {
        let lp_token_value = spot_dex::lp_token_value(&lp_token);
        coin::mint_and_transfer(
            &mut treasury_cap,
            lp_token_value,
            tx_context::sender(ctx),
            ctx,
        );
        let vault = KriyaLpVault {
            id: object::new(ctx),
            lp_token,
            treasury_cap,
        };
        transfer::share_object(vault);
    }

    public fun deposit(
        vault: &mut KriyaLpVault,
        lp_token: KriyaLPToken<CERT, SUI>,
        ctx: &mut TxContext,
    ): Coin<KRIYA_VSUI_LP> {
        let lp_token_value = spot_dex::lp_token_value(&lp_token);
        spot_dex::lp_token_join(&mut vault.lp_token, lp_token);
        coin::mint(
            &mut vault.treasury_cap,
            lp_token_value,
            ctx,
        )
    }

    public fun withdraw(
        vault: &mut KriyaLpVault,
        lp_token: Coin<KRIYA_VSUI_LP>,
        ctx: &mut TxContext,
    ): KriyaLPToken<CERT, SUI> {
        let lp_token_value = coin::value(&lp_token);
        coin::burn(&mut vault.treasury_cap, lp_token);
        spot_dex::lp_token_split(
            &mut vault.lp_token,
            lp_token_value,
            ctx,
        )
    }

    public fun update_icon_url(
        vault: &KriyaLpVault,
        metadata: &mut coin::CoinMetadata<KRIYA_VSUI_LP>,
        url: std::ascii::String,
    ) {
        coin::update_icon_url(&vault.treasury_cap, metadata, url);
    }
}