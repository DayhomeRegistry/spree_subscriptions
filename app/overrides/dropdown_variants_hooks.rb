class DropdownVariantsHooks < Spree::ThemeSupport::HookListener
  replace  :inside_product_cart_form, 'spree/products/dropdown_variants'
end