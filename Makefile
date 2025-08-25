.PHONY: build flash flash-only clean left right

# Default target
all: build

# Build both halves
build:
	@echo "🔨 Building ZMK Docker image..."
	@docker build -t corne-zmk .
	@echo "🔨 Building firmware..."
	@mkdir -p build
	@docker run --rm -v "$$(pwd)/config:/app/config" -v "$$(pwd)/build:/app/build" corne-zmk sh -c " \
		west build -s zmk/app -d build/left -b nice_nano_v2 -- -DSHIELD=corne_left -DZMK_CONFIG=/app/config && \
		west build -s zmk/app -d build/right -b nice_nano_v2 -- -DSHIELD=corne_right -DZMK_CONFIG=/app/config \
	"
	@echo "✅ Build complete!"

# Build only left half
left:
	@echo "🔨 Building LEFT half..."
	@docker run --rm -it -v "$$(pwd):/app" -w /app zmkfirmware/zmk-build-arm:stable sh -c " \
		west build -d build/left -b nice_nano_v2 -- -DSHIELD=corne_left -DZMK_CONFIG=/app/config \
	"

# Build only right half  
right:
	@echo "🔨 Building RIGHT half..."
	@docker run --rm -it -v "$$(pwd):/app" -w /app zmkfirmware/zmk-build-arm:stable sh -c " \
		west build -d build/right -b nice_nano_v2 -- -DSHIELD=corne_right -DZMK_CONFIG=/app/config \
	"

# Interactive flash with prompts
flash: build
	@./flash.sh

# Flash without rebuilding
flash-only:
	@./flash.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@echo "✅ Clean complete!"

# Quick build and flash (asks for confirmation)
quick: build
	@echo "⚡ Quick flash mode - make sure both halves are ready!"
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ]
	@./flash.sh