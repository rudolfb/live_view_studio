defmodule LiveViewStudioWeb.LicenseLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Licenses
  import Number.Currency

  def mount(_params, _session, socket) do
    socket = assign_seats(socket, 2)

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Team License</h1>
    <div id="license">
      <div class="card">
        <div class="content">
          <div class="seats">
            <img src="images/license.svg">
            <span>
              Your license is currently for
              <strong><%= @seats %></strong> seats.
            </span>
          </div>
          <form phx-change="update" >
            <input type="range"
                  min="1" max="10"
                  name="seats"
                  phx-debounce="250"
                  value="<%= @seats %>" />
          </form>
          <div class="amount">
            <%= number_to_currency(@amount, unit: "CHF", format: "%n %u") %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update", %{"seats" => seats}, socket) do
    seats = String.to_integer(seats)
    socket = assign_seats(socket, seats)
    {:noreply, socket}
  end

  defp assign_seats(socket, seats) do
    socket
    |> assign(
      seats: seats,
      amount: Licenses.calculate(seats)
    )
  end
end
