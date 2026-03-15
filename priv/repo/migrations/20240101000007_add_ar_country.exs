defmodule CreditApp.Repo.Migrations.AddArCountry do
  use Ecto.Migration

  def up do
    drop constraint(:credit_applications, :valid_country)

    create constraint(:credit_applications, :valid_country,
      check: "country IN ('ES', 'MX', 'CO', 'PT', 'IT', 'BR', 'AR')"
    )
  end

  def down do
    drop constraint(:credit_applications, :valid_country)

    create constraint(:credit_applications, :valid_country,
      check: "country IN ('ES', 'MX', 'CO', 'PT', 'IT', 'BR')"
    )
  end
end
