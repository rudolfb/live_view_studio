defmodule LiveViewStudioWeb.FlightLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Flights
  alias LiveViewStudio.Airports

  use Timex

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        number: "",
        airport: "",
        matches: [],
        flights: [],
        loading: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Find a Flight</h1>
    <div id="search">

      <form phx-submit="number-search">
        <input type="text" name="number" value="<%= @number %>"
               placeholder="Flight Number"
               autofocus
               autocomplete="off"
               <%=  if @loading, do: "readonly" %> />
        <button type="submit">
          <img src="images/search.svg">
        </button>
      </form>

      <form phx-submit="airportcode-search" phx-change="suggest-airport">
        <input type="text" name="airport" value="<%= @airport %>"
               placeholder="Airport Code"
               list="matches"
               phx-debounce="250"
               autocomplete="off"
               <%= if @loading, do: "readonly" %> />
        <button type="submit">
          <img src="images/search.svg">
        </button>
      </form>

      <datalist id="matches">
        <%= for match <- @matches do %>
          <option value="<%= match %>"><%= match %></option>
        <% end %>
      </datalist>


      <%= if @loading do %>
        <div class="loader">Loading...</div>
      <% end %>

      <div class="flights">
        <ul>
          <%= for flight <- @flights do %>
            <li>
              <div class="first-line">
                <div class="number">
                  Flight #<%= flight.number %>
                </div>
                <div class="origin-destination">
                  <img src="images/location.svg">
                  <%= flight.origin %> to
                  <%= flight.destination %>
                </div>
              </div>
              <div class="second-line">
                <div class="departs">
                  Departs: <%= format_time(flight.departure_time) %>
                </div>
                <div class="arrives">
                  Arrives: <%= format_time (flight.arrival_time) %>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("suggest-airport", %{"airport" => prefix}, socket) do
    socket =
      assign(socket,
        matches: Airports.suggest(prefix),
        number: ""
      )

    {:noreply, socket}
  end

  def handle_event("number-search", %{"number" => number}, socket) do
    send(self(), {:run_number_search, number})

    socket =
      socket
      |> clear_flash()
      |> assign(
        number: number,
        airport: "",
        matches: [],
        flights: [],
        loading: true
      )

    {:noreply, socket}
  end

  def handle_event("airportcode-search", %{"airport" => airport}, socket) do
    send(self(), {:run_airport_search, airport})

    socket =
      socket
      |> clear_flash()
      |> assign(
        number: "",
        airport: airport,
        matches: [],
        flights: [],
        loading: true
      )

    {:noreply, socket}
  end

  def handle_info({:run_number_search, number}, socket) do
    socket =
      update_flight_socket(
        socket,
        Flights.search_by_number(number),
        number
      )

    {:noreply, socket}
  end

  def handle_info({:run_airport_search, airport}, socket) do
    socket =
      update_flight_socket(
        socket,
        Flights.search_by_airport(airport),
        airport
      )

    {:noreply, socket}
  end

  defp format_time(time) do
    Timex.format!(time, "%b %d at %H:%M", :strftime)
  end

  defp update_flight_socket(socket, flights, filter) do
    case flights do
      [] ->
        socket =
          socket
          |> put_flash(:info, "No flights matching \"#{filter}\"")
          |> assign(flights: [], loading: false)

        socket

      flights ->
        assign(socket, flights: flights, loading: false)
    end
  end
end
