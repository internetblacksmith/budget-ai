#!/bin/bash

# Fix broken HTML elements from migration script

echo "🔧 Fixing broken HTML elements from MD3 migration..."

# Fix welcome page
sed -i 's/<md3-display-large class="welcome-title">/<h1 class="md3-display-large welcome-title">/g' app/views/onboarding/welcome.html.erb
sed -i 's/<\/md3-display-large>/<\/h1>/g' app/views/onboarding/welcome.html.erb
sed -i 's/<md3-headline-large>/<h2 class="md3-headline-large">/g' app/views/onboarding/welcome.html.erb
sed -i 's/<\/md3-headline-large>/<\/h2>/g' app/views/onboarding/welcome.html.erb
sed -i 's/<md3-headline-medium>/<h3 class="md3-headline-medium">/g' app/views/onboarding/welcome.html.erb
sed -i 's/<\/md3-headline-medium>/<\/h3>/g' app/views/onboarding/welcome.html.erb
sed -i 's/privacy-md3-md3-card md3-card-elevated md3-md3-card md3-card-elevated-elevated/privacy-card md3-card md3-card-elevated/g' app/views/onboarding/welcome.html.erb
sed -i 's/\.privacy-md3-card md3-card-elevated/.privacy-card/g' app/views/onboarding/welcome.html.erb
sed -i 's/\.privacy-header md3-headline-large/.privacy-header .md3-headline-large/g' app/views/onboarding/welcome.html.erb
sed -i 's/\.setup-preview md3-headline-medium/.setup-preview .md3-headline-medium/g' app/views/onboarding/welcome.html.erb

# Fix banks page
sed -i 's/<md3-display-large>/<h1 class="md3-display-large">/g' app/views/onboarding/banks.html.erb
sed -i 's/<\/md3-display-large>/<\/h1>/g' app/views/onboarding/banks.html.erb
sed -i 's/<md3-headline-medium>/<h3 class="md3-headline-medium">/g' app/views/onboarding/banks.html.erb
sed -i 's/<\/md3-headline-medium>/<\/h3>/g' app/views/onboarding/banks.html.erb
sed -i 's/bank-md3-md3-card md3-card-elevated md3-md3-card md3-card-elevated-elevated/bank-card md3-card md3-card-elevated/g' app/views/onboarding/banks.html.erb
sed -i 's/bank-md3-card md3-card-elevated/bank-card/g' app/views/onboarding/banks.html.erb
sed -i 's/md3-card md3-card-elevated =/card =/g' app/views/onboarding/banks.html.erb
sed -i 's/credit_md3-card md3-card-elevated/credit_card/g' app/views/onboarding/banks.html.erb
sed -i 's/\.bank-md3-card md3-card-elevated/.bank-card/g' app/views/onboarding/banks.html.erb
sed -i 's/\.banks-section md3-display-large/.banks-section .md3-display-large/g' app/views/onboarding/banks.html.erb
sed -i 's/\.bank-md3-card md3-card-elevated md3-headline-medium/.bank-card .md3-headline-medium/g' app/views/onboarding/banks.html.erb

# Fix passphrase page
sed -i 's/<md3-display-large>/<h1 class="md3-display-large">/g' app/views/onboarding/passphrase.html.erb
sed -i 's/<\/md3-display-large>/<\/h1>/g' app/views/onboarding/passphrase.html.erb
sed -i 's/<md3-headline-medium>/<h3 class="md3-headline-medium">/g' app/views/onboarding/passphrase.html.erb
sed -i 's/<\/md3-headline-medium>/<\/h3>/g' app/views/onboarding/passphrase.html.erb
sed -i 's/\.explanation-header md3-headline-medium/.explanation-header .md3-headline-medium/g' app/views/onboarding/passphrase.html.erb
sed -i 's/\.suggestions-section md3-headline-medium/.suggestions-section .md3-headline-medium/g' app/views/onboarding/passphrase.html.erb

# Fix duplicate classes in CSS files
sed -i 's/md3-md3-card md3-card-elevated md3-md3-card md3-card-elevated-elevated/md3-card-elevated/g' app/assets/stylesheets/material-design-3.css
sed -i 's/md3-md3-card md3-card-elevated/md3-card/g' app/assets/stylesheets/material-design-3.css
sed -i 's/md3-md3-card md3-card-elevated-elevated/md3-card-elevated/g' app/assets/stylesheets/material-design-3.css
sed -i 's/md3-md3-card md3-card-elevated-/md3-card-/g' app/assets/stylesheets/material-design-3.css

# Fix material-design.css
sed -i 's/md3-md3-card md3-card-elevated md3-md3-card md3-card-elevated-elevated/md3-card/g' app/assets/stylesheets/material-design.css
sed -i 's/\.md3-md3-card md3-card-elevated/.md3-card/g' app/assets/stylesheets/material-design.css

# Fix JavaScript references
find app/views -name "*.erb" -exec sed -i "s/const md3-card md3-card-elevated/const card/g" {} \;
find app/views -name "*.erb" -exec sed -i "s/\.bank-md3-card md3-card-elevated'/.bank-card'/g" {} \;

echo "✅ Fixed broken HTML elements"