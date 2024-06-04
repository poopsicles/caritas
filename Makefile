.PHONY: build deploy redeploy clean fresh stop

CRATE_NAME := caritas

build:
	dfx generate

deploy:
	dfx start --background || [ $$? -eq 255 ]
	dfx deploy

redeploy:
	make stop
	make build
	dfx start --background --clean || [ $$? -eq 255 ]
	dfx deploy

clean:
	dfx stop
	cargo clean
	rm ./src/$(CRATE_NAME)/$(CRATE_NAME).did || [ $$? -eq 1 ]

fresh:
	make clean
	make redeploy

stop:
	dfx stop
	