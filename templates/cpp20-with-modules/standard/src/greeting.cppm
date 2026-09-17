export module greeting;

import std;

export namespace greeting
{

void greet(std::string_view name)
{
	std::println("Hello, {}!", name);
}

}; // namespace greeting
