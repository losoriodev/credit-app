# Seeds for development (idempotent - safe to run multiple times)

alias CreditApp.Accounts

defmodule Seeds do
  def create_user_if_not_exists(attrs) do
    email = attrs["email"]

    case Accounts.get_user_by_email(email) do
      nil ->
        {:ok, user} = Accounts.create_user(attrs)
        IO.puts("Created user: #{email} (#{attrs["role"]})")
        user

      user ->
        IO.puts("User already exists: #{email} (#{attrs["role"]})")
        user
    end
  end
end

# Create admin user
Seeds.create_user_if_not_exists(%{
  "email" => "admin@creditapp.com",
  "password" => "admin123456",
  "role" => "admin"
})

# Create analyst users per country
for {country, email} <- [
      {"ES", "analyst_es@creditapp.com"},
      {"MX", "analyst_mx@creditapp.com"},
      {"CO", "analyst_co@creditapp.com"}
    ] do
  Seeds.create_user_if_not_exists(%{
    "email" => email,
    "password" => "analyst123456",
    "role" => "analyst",
    "country" => country
  })
end

# Create viewer user
Seeds.create_user_if_not_exists(%{
  "email" => "viewer@creditapp.com",
  "password" => "viewer123456",
  "role" => "viewer"
})

IO.puts("\nSeeds completed!")
IO.puts("Login: POST /api/auth/login {\"email\": \"admin@creditapp.com\", \"password\": \"admin123456\"}")
