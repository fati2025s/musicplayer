class FilterByArtist extends Filter {
    private String[] artist;
    public FilterByArtist(String... artist) {
        this.artist = artist;
    }
    public boolean accept(Song music) {
        for(int i=0;i<artist.length;i++){
            if(artist[i].equals(music.getArtist())){
                return true;
            }
        }
        return false;
    }
}
