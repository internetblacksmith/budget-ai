#!/bin/bash

echo "===================================="
echo "   Budget AI - Easy Docker Setup"
echo "===================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    echo ""
    echo "Please install Docker:"
    echo "- Mac: https://www.docker.com/products/docker-desktop/"
    echo "- Linux: https://docs.docker.com/engine/install/"
    echo ""
    exit 1
fi

echo "Docker is installed. Starting Budget AI..."
echo ""
echo "This may take a few minutes on first run while downloading everything."
echo ""

# Start all services
docker-compose up -d

echo ""
echo "===================================="
echo "   Budget AI is starting up!"
echo "===================================="
echo ""
echo "Please wait about 30 seconds for everything to start..."
echo ""

# Wait for services to be ready
sleep 30

echo "Budget AI should now be running!"
echo ""
echo "Open your web browser and go to:"
echo ""
echo "   http://localhost:3000"
echo ""
echo "To stop Budget AI later, run: ./stop-budget-ai.sh"
echo ""